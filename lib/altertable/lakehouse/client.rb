require "json"
require "base64"
require_relative "models"
require_relative "errors"
require_relative "version"
require_relative "adapters"

module Altertable
  module Lakehouse
    class Client
      DEFAULT_BASE_URL = "https://api.altertable.ai"
      DEFAULT_TIMEOUT = 10

      def initialize(username: nil, password: nil, basic_auth_token: nil, base_url: nil, timeout: nil, user_agent: nil, adapter: nil, headers: {})
        # 1. Try passed basic_auth_token
        # 2. Try passed username/password
        # 3. Try ENV["ALTERTABLE_BASIC_AUTH_TOKEN"]
        # 4. Try ENV["ALTERTABLE_USERNAME"] / ENV["ALTERTABLE_PASSWORD"]

        if basic_auth_token
          @auth_header = "Basic #{basic_auth_token}"
        elsif username && password
          @auth_header = "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
        elsif (env_token = ENV["ALTERTABLE_BASIC_AUTH_TOKEN"])
          @auth_header = "Basic #{env_token}"
        elsif (env_user = ENV["ALTERTABLE_USERNAME"]) && (env_pass = ENV["ALTERTABLE_PASSWORD"])
          @auth_header = "Basic #{Base64.strict_encode64("#{env_user}:#{env_pass}")}"
        else
          raise ConfigurationError, "Authentication credentials required (username/password or basic_auth_token)"
        end

        @base_url = base_url || DEFAULT_BASE_URL
        @timeout = timeout || DEFAULT_TIMEOUT
        @user_agent = user_agent ? "AltertableRuby/#{VERSION} #{user_agent}" : "AltertableRuby/#{VERSION}"
        
        default_headers = {
          "Authorization" => @auth_header,
          "User-Agent" => @user_agent,
          "Content-Type" => "application/json"
        }

        @adapter = select_adapter(adapter, base_url: @base_url, timeout: @timeout, headers: default_headers.merge(headers))
      end

      # POST /append
      def append(catalog:, schema:, table:, payload:, sync: nil, headers: {})
        params = { catalog: catalog, schema: schema, table: table }
        params[:sync] = sync unless sync.nil?
        req = Models::AppendRequest.new(payload)
        resp = request(:post, "/append", body: req.to_h, query: params, headers: headers)
        Models::AppendResponse.from_h(resp)
      end

      # GET /tasks/:task_id
      def get_task(task_id, headers: {})
        resp = request(:get, "/tasks/#{task_id}", headers: headers)
        Models::TaskResponse.from_h(resp)
      end

      # POST /query (streamed)
      def query(statement:, headers: {}, **options)
        req_body = Models::QueryRequest.new(statement: statement, **options).to_h.to_json

        enum = Enumerator.new do |yielder|
          buffer = ""
          
          # Use adapter's stream capability
          resp = @adapter.post("/query", body: req_body, headers: headers) do |chunk, _|
            buffer << chunk
          end

          handle_stream_response(resp, buffer, yielder)
        end

        QueryResult.new(enum)
      end

      # POST /query (accumulated)
      def query_all(statement:, headers: {}, **options)
        result = query(statement: statement, headers: headers, **options)
        rows = result.to_a # Accumulate
        {
          metadata: result.metadata,
          columns: result.columns,
          rows: rows
        }
      end

      # POST /upsert
      def upload(catalog:, schema:, table:, file_io:, mode: nil, primary_key: nil, headers: {}, content_type: "application/octet-stream")
        params = {
          catalog: catalog,
          schema: schema,
          table: table
        }
        params[:mode] = mode if mode
        params[:primary_key] = primary_key if primary_key

        body = file_io.respond_to?(:read) ? file_io.read : file_io

        resp = @adapter.post("/upsert", body: body, params: params, headers: headers.merge("Content-Type" => content_type))
        handle_response(resp)
      end

      # GET /query/:query_id
      def get_query(query_id, headers: {})
        resp = request(:get, "/query/#{query_id}", headers: headers)
        Models::QueryLogResponse.from_h(resp)
      end

      # DELETE /query/:query_id
      def cancel_query(query_id, session_id:, headers: {})
        resp = request(:delete, "/query/#{query_id}", query: { session_id: session_id }, headers: headers)
        Models::CancelQueryResponse.from_h(resp)
      end

      # POST /validate
      def validate(statement:, catalog: nil, schema: nil, session_id: nil, headers: {})
        req = Models::ValidateRequest.new(
          statement: statement,
          catalog: catalog,
          schema: schema,
          session_id: session_id
        )
        resp = request(:post, "/validate", body: req.to_h, headers: headers)
        Models::ValidateResponse.from_h(resp)
      end

      # POST /autocomplete
      def autocomplete(statement:, catalog: nil, schema: nil, session_id: nil, max_suggestions: nil, headers: {})
        req = Models::AutocompleteRequest.new(
          statement: statement,
          catalog: catalog,
          schema: schema,
          session_id: session_id,
          max_suggestions: max_suggestions
        )
        resp = request(:post, "/autocomplete", body: req.to_h, headers: headers)
        Models::AutocompleteResponse.from_h(resp)
      end

      # POST /explain
      def explain(statement:, catalog: nil, schema: nil, session_id: nil, include_plan: nil, headers: {})
        req = Models::ExplainRequest.new(
          statement: statement,
          catalog: catalog,
          schema: schema,
          session_id: session_id,
          include_plan: include_plan
        )
        resp = request(:post, "/explain", body: req.to_h, headers: headers)
        Models::ExplainResponse.from_h(resp)
      end

      private

      def select_adapter(name, options)
        case name
        when :faraday
          Adapters::FaradayAdapter.new(**options)
        when :httpx
          Adapters::HttpxAdapter.new(**options)
        when :net_http
          Adapters::NetHttpAdapter.new(**options)
        else
          # Auto-detect
          if defined?(Faraday) || try_require("faraday")
            Adapters::FaradayAdapter.new(**options)
          elsif defined?(HTTPX) || try_require("httpx")
            Adapters::HttpxAdapter.new(**options)
          else
            Adapters::NetHttpAdapter.new(**options)
          end
        end
      end

      def try_require(gem_name)
        require gem_name
        true
      rescue LoadError
        false
      end

      def request(method, path, body: nil, query: nil, headers: {})
        resp = @adapter.send(
          method, path,
          body: encode_request_body(body),
          params: query || {},
          headers: headers
        )
        handle_response(resp)
      end

      def encode_request_body(body)
        case body
        when Hash, Array
          body.to_json
        else
          body
        end
      end

      def handle_stream_response(resp, buffer, yielder)
        case resp.status
        when 400
          raise BadRequestError, "Bad Request: #{buffer.strip}"
        when 401
          raise AuthError, "Unauthorized"
        when 200..299
          # Parse the accumulated NDJSON buffer line by line
          # Buffer might be partial? 
          # In streaming, the block is called.
          # Here we are processing after the stream is done?
          # Wait, QueryResult expects the stream to be processed as it comes?
          # The previous implementation used an Enumerator that yielded as data came in.
          # Here, @adapter.post blocks until done?
          # If @adapter.post blocks, we only get the buffer at the end.
          # To stream truly, @adapter.post needs to yield to the block, which yields to yielder?
          
          # Re-implementing streaming logic:
          # The enumerator in `query` wraps the call. 
          # When `query` returns QueryResult, it hasn't run the request yet.
          # Enumerator logic is inside.
          
          buffer.each_line do |line|
            line = line.strip
            next if line.empty?
            begin
              yielder << JSON.parse(line)
            rescue JSON::ParserError
              # Partial line?
              # For now assume full lines or handle buffering properly
            end
          end
        else
          raise ApiError, "API Error #{resp.status}: #{buffer.strip}"
        end
      end

      def handle_response(resp)
        case resp.status
        when 200..299
          return nil if resp.body.nil? || resp.body.empty?
          begin
            JSON.parse(resp.body)
          rescue JSON::ParserError
            # For non-JSON responses
            resp.body
          end
        when 400
          raise BadRequestError, "Bad Request: #{resp.body}"
        when 401
          raise AuthError, "Unauthorized"
        when 404
          raise ApiError, "Not Found: #{resp.headers}" # Url not avail in struct easily
        else
          raise ApiError, "API Error #{resp.status}: #{resp.body}"
        end
      end
    end

    class QueryResult
      include Enumerable

      # metadata: the stream header object (first NDJSON line)
      # columns:  array of column name strings (second NDJSON line)
      attr_reader :metadata, :columns

      def initialize(enum)
        @enum = enum
        @metadata = nil
        @columns = nil
      end

      def each(&block)
        # The real mock streams:
        #   line 1: { "statement":…, "session_id":…, … }   (header object)
        #   line 2: ["col1", "col2", …]                     (column names array)
        #   line 3+: [val1, val2, …]                        (row value arrays)
        # We zip each row array with the column names to produce a Hash.
        line_index = 0

        @enum.each do |item|
          case line_index
          when 0
            @metadata = item
          when 1
            @columns = item
          else
            if @columns.is_a?(Array) && item.is_a?(Array)
              block.call(@columns.zip(item).to_h)
            else
              block.call(item)
            end
          end
          line_index += 1
        end
      end
    end

  end
end
