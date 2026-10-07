module Altertable
  module Lakehouse
    class Error < StandardError
      attr_reader :operation, :http_method, :http_path, :status_code, :retriable, :request_id, :cause

      def initialize(message, operation: nil, http_method: nil, http_path: nil, status_code: nil, retriable: false, request_id: nil, cause: nil)
        super(message)
        @operation = operation
        @http_method = http_method
        @http_path = http_path
        @status_code = status_code
        @retriable = retriable
        @request_id = request_id
        @cause = cause
      end
    end

    class AuthError < Error; end
    class BadRequestError < Error; end
    class NetworkError < Error; end
    class TimeoutError < Error; end
    class SerializationError < Error; end
    class ParseError < Error; end

    # Backend-emitted `{ "error": string }` line in a /query NDJSON stream.
    # `line_index` is the zero-based index of that line.
    class QueryError < Error
      attr_reader :line_index

      def initialize(message, line_index:, operation: nil, http_method: nil, http_path: nil, status_code: nil, retriable: false, request_id: nil, cause: nil)
        super(
          message,
          operation: operation,
          http_method: http_method,
          http_path: http_path,
          status_code: status_code,
          retriable: retriable,
          request_id: request_id,
          cause: cause
        )
        @line_index = line_index
      end
    end

    class ApiError < Error; end
    class ConfigurationError < Error; end
  end
end
