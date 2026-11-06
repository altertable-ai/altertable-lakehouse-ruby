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
      DEFAULT_OPEN_TIMEOUT = 5

      def initialize(username: nil, password: nil, basic_auth_token: nil, base_url: nil, timeout: nil, open_timeout: nil, user_agent: nil, adapter: nil, headers: {}, **)
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
        @open_timeout = open_timeout || DEFAULT_OPEN_TIMEOUT
        @user_agent = user_agent ? "AltertableRuby/#{VERSION} #{user_agent}" : "AltertableRuby/#{VERSION}"
        
        default_headers = {
          "Authorization" => @auth_header,
          "User-Agent" => @user_agent
        }

        @adapter = select_adapter(adapter, base_url: @base_url, timeout: @timeout, open_timeout: @open_timeout, headers: default_headers.merge(headers), **)
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
      def query(statement:, headers: {}, **)
        req_body = Models::QueryRequest.new(statement: statement, **).to_h.to_json

        enum = Enumerator.new do |yielder|
          stream = NdjsonStream.new { |value| yielder << value }

          # The adapter yields each body chunk with the response status (when
          # it knows it), so rows reach the caller as they arrive.
          resp = @adapter.post("/query", body: req_body, headers: json_headers(headers)) do |chunk, status|
            stream.write(chunk, status)
          end

          handle_stream_response(resp, stream)
        end

        QueryResult.new(enum)
      end

      # POST /query (accumulated)
      def query_all(statement:, headers: {}, **)
        result = query(statement: statement, headers: headers, **)
        rows = result.to_a # Accumulate
        {
          metadata: result.metadata,
          columns: result.columns,
          rows: rows
        }
      end

      # POST /upload
      def upload(catalog:, schema:, table:, mode:, file_io:, headers: {})
        params = {
          catalog: catalog,
          schema: schema,
          table: table,
          mode: mode
        }

        body = file_io.respond_to?(:read) ? file_io.read : file_io

        resp = @adapter.post("/upload", body: body, params: params, headers: headers)
        handle_response(resp)
      end

      # POST /upsert
      def upsert(catalog:, schema:, table:, primary_key:, file_io:, headers: {})
        params = {
          catalog: catalog,
          schema: schema,
          table: table,
          primary_key: primary_key
        }

        body = file_io.respond_to?(:read) ? file_io.read : file_io

        resp = @adapter.post("/upsert", body: body, params: params, headers: headers)
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
          headers: body.nil? ? headers : json_headers(headers)
        )
        handle_response(resp)
      end

      def json_headers(headers)
        { "Content-Type" => "application/json" }.merge(headers)
      end

      def encode_request_body(body)
        case body
        when Hash, Array
          body.to_json
        else
          body
        end
      end

      def handle_stream_response(resp, stream)
        case resp.status
        when 200..299
          stream.finish
        when 400
          raise BadRequestError, "Bad Request: #{stream_error_body(resp, stream)}"
        when 401
          raise AuthError, "Unauthorized"
        else
          raise ApiError, "API Error #{resp.status}: #{stream_error_body(resp, stream)}"
        end
      end

      # Adapters stream error bodies to the block too, except Net::HTTP, which
      # returns them in the response.
      def stream_error_body(resp, stream)
        body = stream.body
        body = resp.body.to_s if body.empty?
        body.strip
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

    # Splits a /query NDJSON body into JSON values as chunks arrive, carrying a
    # partial trailing line over to the next chunk. Until a chunk comes with a
    # 2xx status, the body is only buffered: it may be an error message, or the
    # adapter may not know the status before the response ends.
    class NdjsonStream
      def initialize(&on_value)
        @on_value = on_value
        @buffer = String.new(encoding: Encoding::BINARY)
        @streaming = false
      end

      def write(chunk, status)
        @buffer << chunk.b
        @streaming ||= !status.nil? && (200..299).cover?(status)
        emit_complete_lines if @streaming
      end

      # Emits whatever is left once the response ended with a 2xx status.
      def finish
        emit_complete_lines
        emit(@buffer)
        @buffer = String.new(encoding: Encoding::BINARY)
      end

      # The buffered, not yet emitted body.
      def body
        @buffer.dup.force_encoding(Encoding::UTF_8)
      end

      private

      def emit_complete_lines
        last_newline = @buffer.rindex("\n")
        return unless last_newline

        complete = @buffer.byteslice(0..last_newline)
        @buffer = @buffer.byteslice((last_newline + 1)..)
        complete.each_line { |line| emit(line) }
      end

      def emit(line)
        line = line.dup.force_encoding(Encoding::UTF_8).strip
        return if line.empty?

        @on_value.call(JSON.parse(line))
      rescue JSON::ParserError => e
        raise ParseError.new(
          "Malformed /query line: #{e.message}",
          operation: "query",
          http_method: "POST",
          http_path: "/query",
          cause: e
        )
      end
    end

    ColumnDescriptor = Data.define(:name, :type)

    class QueryResult
      include Enumerable

      # metadata: the stream header object (first NDJSON line)
      # columns:  ColumnDescriptor array (second NDJSON line)
      attr_reader :metadata, :columns

      def initialize(enum)
        @enum = enum
        @metadata = nil
        @columns = nil
        @column_names = nil
      end

      def each(&block)
        # The mock streams NDJSON:
        #   line 1: metadata object
        #   line 2: column descriptors, or { "error": string }
        #   line 3+: row arrays, or { "error": string }
        # Row arrays are zipped with column names into hashes.
        line_index = 0

        @enum.each do |item|
          if line_index.positive? && (message = stream_error_message(item))
            raise QueryError.new(
              message,
              line_index: line_index,
              operation: "query",
              http_method: "POST",
              http_path: "/query"
            )
          end

          case line_index
          when 0
            @metadata = item
          when 1
            @columns = column_descriptors(item)
            @column_names = @columns.map(&:name)
          else
            if item.is_a?(Array)
              block.call(@column_names.zip(item).to_h)
            else
              block.call(item)
            end
          end
          line_index += 1
        end
      end

      private

      # A post-metadata JSON object with an `error` string is a stream failure,
      # not column schema or a row.
      def stream_error_message(item)
        return unless item.is_a?(Hash)

        message = item["error"]
        message if message.is_a?(String)
      end

      def column_descriptors(columns)
        unless columns.is_a?(Array)
          raise column_parse_error("expected an array of column objects, got #{columns.inspect}")
        end

        columns.map do |column|
          name = column["name"] if column.is_a?(Hash)
          type = column["type"] if column.is_a?(Hash)
          unless name.is_a?(String) && type.is_a?(String)
            raise column_parse_error("expected a { \"name\", \"type\" } column object, got #{column.inspect}")
          end

          ColumnDescriptor.new(name: name, type: type)
        end
      end

      def column_parse_error(message)
        ParseError.new(
          "Malformed /query column line: #{message}",
          operation: "query",
          http_method: "POST",
          http_path: "/query"
        )
      end
    end

  end
end
