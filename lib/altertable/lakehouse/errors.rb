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
    class ApiError < Error; end
    class ConfigurationError < Error; end
  end
end
