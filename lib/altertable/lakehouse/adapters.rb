module Altertable
  module Lakehouse
    module Adapters
      Response = Struct.new(:status, :body, :headers)

      class Base
        def initialize(base_url:, timeout:, headers: {})
          @base_url = base_url
          @timeout = timeout
          @headers = headers
        end

        def get(path, body: nil, params: {}, headers: {}, &_block)
          raise NotImplementedError
        end

        def post(path, body: nil, params: {}, headers: {}, &_block)
          raise NotImplementedError
        end

        def delete(path, body: nil, params: {}, headers: {}, &_block)
          raise NotImplementedError
        end
      end

      class FaradayAdapter < Base
        def initialize(base_url:, timeout:, headers: {})
          super
          require "faraday"
          require "faraday/retry"
          require "faraday/net_http"
          
          @conn = Faraday.new(url: @base_url) do |f|
            @headers.each { |k, v| f.headers[k] = v }
            f.options.timeout = @timeout
            f.request :retry, max: 3, interval: 0.05, backoff_factor: 2
            f.adapter Faraday.default_adapter
          end
        end

        def get(path, body: nil, params: {}, headers: {}, &_block)
          resp = @conn.get(path, params, headers)
          wrap_response(resp)
        rescue Faraday::ConnectionFailed => e
          raise Altertable::Lakehouse::NetworkError, e.message
        rescue Faraday::TimeoutError => e
          raise Altertable::Lakehouse::TimeoutError, e.message
        end

        def post(path, body: nil, params: {}, headers: {}, &block)
          resp = @conn.post(path) do |req|
            req.params = params if params
            req.headers = req.headers.merge(headers) unless headers.empty?
            req.body = body
            req.options.on_data = block if block_given?
          end
          wrap_response(resp)
        rescue Faraday::ConnectionFailed => e
          raise Altertable::Lakehouse::NetworkError, e.message
        rescue Faraday::TimeoutError => e
          raise Altertable::Lakehouse::TimeoutError, e.message
        end

        def delete(path, body: nil, params: {}, headers: {}, &_block)
          resp = @conn.delete(path, params, headers)
          wrap_response(resp)
        rescue Faraday::ConnectionFailed => e
          raise Altertable::Lakehouse::NetworkError, e.message
        rescue Faraday::TimeoutError => e
          raise Altertable::Lakehouse::TimeoutError, e.message
        end

        private

        def wrap_response(resp)
          Response.new(resp.status, resp.body, resp.headers)
        end
      end

      class HttpxAdapter < Base
        def initialize(base_url:, timeout:, headers: {})
          super
          require "httpx"
          # Configure retries plugin if available or implement manual retries?
          # Httpx has built-in retries via plugin.
          @client = HTTPX.plugin(:retries).with(
            timeout: { operation_timeout: @timeout },
            headers: @headers,
            base_url: @base_url
          )
        end

        def get(path, body: nil, params: {}, headers: {}, &_block)
          resp = @client.with(headers: headers).get(path, params: params)
          wrap_response(resp)
        end

        def post(path, body: nil, params: {}, headers: {}, &block)
          client = @client.with(headers: headers)
          if block_given?
            # Stream response body
            # HTTPX response streaming:
            response = client.request("POST", path, body: body, params: params, stream: true)
            
            # Check for error immediately
            if response.is_a?(HTTPX::ErrorResponse)
              raise Altertable::Lakehouse::NetworkError, response.error.message
            end

            response.body.each do |chunk|
              block.call(chunk, response.headers["content-length"])
            end
            wrap_response(response)
          else
            resp = client.post(path, body: body, params: params)
            wrap_response(resp)
          end
        end

        def delete(path, body: nil, params: {}, headers: {}, &_block)
          resp = @client.with(headers: headers).delete(path, params: params)
          wrap_response(resp)
        end

        private

        def wrap_response(resp)
          if resp.is_a?(HTTPX::ErrorResponse)
            raise Altertable::Lakehouse::NetworkError, resp.error.message
          end
          Response.new(resp.status, resp.to_s, resp.headers)
        end
      end

      class NetHttpAdapter < Base
        def initialize(base_url:, timeout:, headers: {})
          super
          require "net/http"
          require "uri"
          @uri = URI.parse(@base_url)
        end

        def get(path, body: nil, params: {}, headers: {}, &block)
          request(Net::HTTP::Get, path, params: params, headers: headers, &block)
        end

        def post(path, body: nil, params: {}, headers: {}, &block)
          request(Net::HTTP::Post, path, body: body, params: params, headers: headers, &block)
        end

        def delete(path, body: nil, params: {}, headers: {}, &block)
          request(Net::HTTP::Delete, path, params: params, headers: headers, &block)
        end

        private

        def request(klass, path, body: nil, params: {}, headers: {}, &block)
          # Construct full URI for request
          uri = URI.join(@uri, path)
          uri.query = URI.encode_www_form(params) unless params.nil? || params.empty?

          req = klass.new(uri)
          @headers.merge(headers).each { |k, v| req[k] = v }
          req.body = body if body

          # Net::HTTP start
          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: @timeout, read_timeout: @timeout) do |http|
            if block_given?
              http.request(req) do |response|
                # Stream the body if block is given
                if response.is_a?(Net::HTTPSuccess)
                  response.read_body do |chunk|
                    block.call(chunk, response.content_length)
                  end
                end
                # Return wrapped response (body might be empty if consumed?)
                # If we consumed the body with read_body, response.body is nil.
                # But our Response struct expects body. For streaming, we might not need body in the Response if block handled it.
                return Response.new(response.code.to_i, response.body, response.to_hash) 
              end
            else
              resp = http.request(req)
              Response.new(resp.code.to_i, resp.body, resp.to_hash)
            end
          end
        rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
          raise Altertable::Lakehouse::NetworkError, e.message
        end
      end
    end
  end
end
