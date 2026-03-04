require "faraday"
require "faraday/retry"
require "faraday/net_http"
require "json"
require_relative "models"
require_relative "errors"
require_relative "version"

module Altertable
  module Lakehouse
    class Client
      DEFAULT_BASE_URL = "https://api.altertable.ai"
      DEFAULT_TIMEOUT = 10

      def initialize(api_key: nil, base_url: nil, timeout: nil, user_agent: nil)
        @api_key = api_key || ENV["ALTERTABLE_API_KEY"]
        raise AuthError, "API key is required" unless @api_key

        @base_url = base_url || DEFAULT_BASE_URL
        @timeout = timeout || DEFAULT_TIMEOUT
        @user_agent = user_agent ? "AltertableRuby/#{VERSION} #{user_agent}" : "AltertableRuby/#{VERSION}"
        
        @conn = Faraday.new(url: @base_url) do |f|
          f.headers["Authorization"] = "Bearer #{@api_key}"
          f.headers["User-Agent"] = @user_agent
          f.headers["Content-Type"] = "application/json"
          f.options.timeout = @timeout
          f.request :retry, max: 3, interval: 0.05, backoff_factor: 2
          f.adapter Faraday.default_adapter
        end
      end

      # POST /append
      def append(catalog:, schema:, table:, payload:)
        params = { catalog: catalog, schema: schema, table: table }
        req = Models::AppendRequest.new(payload)
        resp = request(:post, "/append", body: req.to_h, query: params)
        Models::AppendResponse.from_h(resp)
      end

      # POST /query (streamed)
      def query(statement:, **options)
        req_body = Models::QueryRequest.new(statement: statement, **options).to_h.to_json
        
        enum = Enumerator.new do |yielder|
          buffer = ""
          @conn.post("/query") do |req|
            req.headers["Content-Type"] = "application/json"
            req.body = req_body
            req.options.on_data = Proc.new do |chunk, _|
              buffer << chunk
              while (line_end = buffer.index("\n"))
                line = buffer.slice!(0, line_end + 1).strip
                next if line.empty?
                begin
                  yielder << JSON.parse(line)
                rescue JSON::ParserError
                  # Incomplete JSON or error
                end
              end
            end
          end
          
          # Process remaining buffer
          unless buffer.empty?
            begin
              yielder << JSON.parse(buffer.strip)
            rescue JSON::ParserError
              # Ignore malformed tail
            end
          end
        end
        
        QueryResult.new(enum)
      end

      # POST /query (accumulated)
      def query_all(statement:, **options)
        result = query(statement: statement, **options)
        rows = result.to_a # Accumulate
        {
          metadata: result.metadata,
          columns: result.columns,
          rows: rows
        }
      end

      # POST /upload
      def upload(catalog:, schema:, table:, format:, mode:, file_io:, primary_key: nil)
        params = { 
          catalog: catalog, 
          schema: schema, 
          table: table, 
          format: format, 
          mode: mode 
        }
        params[:primary_key] = primary_key if primary_key

        # Use a separate connection for multipart/binary if needed, 
        # but spec says body is octet-stream.
        resp = @conn.post("/upload") do |req|
          req.params = params
          req.headers["Content-Type"] = "application/octet-stream"
          req.body = file_io # IO object or string
        end
        
        handle_response(resp)
      end

      # GET /query/:query_id
      def get_query(query_id)
        resp = request(:get, "/query/#{query_id}")
        Models::QueryLogResponse.from_h(resp)
      end

      # DELETE /query/:query_id
      def cancel_query(query_id, session_id:)
        resp = request(:delete, "/query/#{query_id}", query: { session_id: session_id })
        Models::CancelQueryResponse.from_h(resp)
      end

      # POST /validate
      def validate(statement:)
        req = Models::ValidateRequest.new(statement: statement)
        resp = request(:post, "/validate", body: req.to_h)
        Models::ValidateResponse.from_h(resp)
      end

      private

      def request(method, path, body: nil, query: nil, stream: false, &block)
        resp = @conn.send(method, path) do |req|
          req.params = query if query
          req.body = body.to_json if body
          if stream
            req.options.on_data = block
          end
        end
        
        return if stream # Block handles data
        
        handle_response(resp)
      rescue Faraday::ConnectionFailed => e
        raise NetworkError, e.message
      rescue Faraday::TimeoutError => e
        raise TimeoutError, e.message
      end

      def handle_response(resp)
        case resp.status
        when 200..299
          return nil if resp.body.nil? || resp.body.empty?
          begin
            JSON.parse(resp.body)
          rescue JSON::ParserError
            # For non-JSON responses (like empty upload response?)
            resp.body
          end
        when 400
          raise BadRequestError, "Bad Request: #{resp.body}"
        when 401
          raise AuthError, "Unauthorized"
        when 404
          raise ApiError, "Not Found: #{resp.url}" # Could be specific
        else
          raise ApiError, "API Error #{resp.status}: #{resp.body}"
        end
      end
    end
    
    class QueryResult
      include Enumerable
      
      attr_reader :metadata, :columns
      
      def initialize(enum)
        @enum = enum
        @metadata = nil
        @columns = nil
      end
      
      def each(&block)
        # We need to wrap the enum to extract metadata/columns first
        # Note: This will re-trigger the request if enumerated multiple times
        first = true
        second = true
        
        @enum.each do |item|
          if first
            @metadata = item
            first = false
          elsif second
            @columns = item
            second = false
          else
            block.call(item)
          end
        end
      end
    end

  end
end
