# typed: true

module Altertable
  module Lakehouse
    VERSION = T.let(T.unsafe(nil), String)

    class Error < StandardError
      sig { returns(T.nilable(String)) }
      attr_reader :operation

      sig { returns(T.nilable(String)) }
      attr_reader :http_method

      sig { returns(T.nilable(String)) }
      attr_reader :http_path

      sig { returns(T.nilable(Integer)) }
      attr_reader :status_code

      sig { returns(T::Boolean) }
      attr_reader :retriable

      sig { returns(T.nilable(String)) }
      attr_reader :request_id

      sig { returns(T.nilable(Exception)) }
      attr_reader :cause

      sig do
        params(
          message: String,
          operation: T.nilable(String),
          http_method: T.nilable(String),
          http_path: T.nilable(String),
          status_code: T.nilable(Integer),
          retriable: T::Boolean,
          request_id: T.nilable(String),
          cause: T.nilable(Exception)
        ).void
      end
      def initialize(message, operation: nil, http_method: nil, http_path: nil, status_code: nil, retriable: false, request_id: nil, cause: nil); end
    end

    class AuthError < Error; end
    class BadRequestError < Error; end
    class NetworkError < Error; end
    class TimeoutError < Error; end
    class SerializationError < Error; end
    class ParseError < Error; end
    class ApiError < Error; end
    class ConfigurationError < Error; end

    class Client
      DEFAULT_BASE_URL = T.let(T.unsafe(nil), String)
      DEFAULT_TIMEOUT = T.let(T.unsafe(nil), Integer)

      sig do
        params(
          username: T.nilable(String),
          password: T.nilable(String),
          basic_auth_token: T.nilable(String),
          base_url: T.nilable(String),
          timeout: T.nilable(T.any(Integer, Float)),
          user_agent: T.nilable(String),
          adapter: T.nilable(Symbol)
        ).void
      end
      def initialize(username: nil, password: nil, basic_auth_token: nil, base_url: nil, timeout: nil, user_agent: nil, adapter: nil); end

      sig do
        params(
          catalog: String,
          schema: String,
          table: String,
          payload: T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]]),
          sync: T.nilable(T::Boolean)
        ).returns(Models::AppendResponse)
      end
      def append(catalog:, schema:, table:, payload:, sync: nil); end

      sig { params(task_id: String).returns(Models::TaskResponse) }
      def get_task(task_id); end

      sig { params(statement: String, options: T.untyped).returns(QueryResult) }
      def query(statement:, **options); end

      sig { params(statement: String, options: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
      def query_all(statement:, **options); end

      sig do
        params(
          catalog: String,
          schema: String,
          table: String,
          format: String,
          mode: String,
          file_io: T.untyped,
          primary_key: T.nilable(String)
        ).returns(T.untyped)
      end
      def upload(catalog:, schema:, table:, format:, mode:, file_io:, primary_key: nil); end

      sig { params(query_id: String).returns(Models::QueryLogResponse) }
      def get_query(query_id); end

      sig { params(query_id: String, session_id: String).returns(Models::CancelQueryResponse) }
      def cancel_query(query_id, session_id:); end

      sig do
        params(
          statement: String,
          catalog: T.nilable(String),
          schema: T.nilable(String),
          session_id: T.nilable(String)
        ).returns(Models::ValidateResponse)
      end
      def validate(statement:, catalog: nil, schema: nil, session_id: nil); end

      sig do
        params(
          statement: String,
          catalog: T.nilable(String),
          schema: T.nilable(String),
          session_id: T.nilable(String),
          max_suggestions: T.nilable(Integer)
        ).returns(Models::AutocompleteResponse)
      end
      def autocomplete(statement:, catalog: nil, schema: nil, session_id: nil, max_suggestions: nil); end

      private

      sig { params(name: T.nilable(Symbol), options: T.untyped).returns(T.untyped) }
      def select_adapter(name, options); end

      sig { params(gem_name: String).returns(T::Boolean) }
      def try_require(gem_name); end

      sig do
        params(
          method: Symbol,
          path: String,
          body: T.untyped,
          query: T.nilable(T::Hash[T.any(Symbol, String), T.untyped])
        ).returns(T.untyped)
      end
      def request(method, path, body: nil, query: nil); end

      sig { params(resp: Adapters::Response, buffer: String, yielder: Enumerator::Yielder).void }
      def handle_stream_response(resp, buffer, yielder); end

      sig { params(resp: Adapters::Response).returns(T.untyped) }
      def handle_response(resp); end
    end

    class QueryResult
      include Enumerable

      sig { returns(T.untyped) }
      attr_reader :metadata

      sig { returns(T.untyped) }
      attr_reader :columns

      sig { params(enum: T.untyped).void }
      def initialize(enum); end

      sig { params(blk: T.untyped).void }
      def each(&blk); end
    end

    module Models
      class Request
        sig { returns(T.untyped) }
        def to_h; end
      end

      class AppendRequest < Request
        sig { returns(T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]])) }
        attr_reader :payload

        sig { params(payload: T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]])).void }
        def initialize(payload); end

        sig { returns(T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]])) }
        def to_h; end
      end

      class AppendResponse < Request
        sig { returns(T::Boolean) }
        attr_reader :ok

        sig { returns(T.nilable(String)) }
        attr_reader :error_code

        sig { returns(T.nilable(String)) }
        attr_reader :error_message

        sig { returns(T.nilable(String)) }
        attr_reader :task_id

        sig do
          params(
            ok: T::Boolean,
            error_code: T.nilable(String),
            error_message: T.nilable(String),
            task_id: T.nilable(String)
          ).void
        end
        def initialize(ok:, error_code: nil, error_message: nil, task_id: nil); end

        sig { params(h: T::Hash[String, T.untyped]).returns(AppendResponse) }
        def self.from_h(h); end
      end

      class TaskResponse < Request
        sig { returns(String) }
        attr_reader :task_id

        sig { returns(String) }
        attr_reader :status

        sig { params(task_id: String, status: String).void }
        def initialize(task_id:, status:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(TaskResponse) }
        def self.from_h(h); end
      end

      class QueryRequest < Request
        sig { returns(String) }
        attr_reader :statement

        sig { returns(T.nilable(String)) }
        attr_reader :catalog

        sig { returns(T.nilable(String)) }
        attr_reader :schema

        sig { returns(T.nilable(String)) }
        attr_reader :session_id

        sig { returns(T.nilable(String)) }
        attr_reader :compute_size

        sig { returns(T.nilable(T::Boolean)) }
        attr_reader :sanitize

        sig { returns(T.nilable(Integer)) }
        attr_reader :limit

        sig { returns(T.nilable(Integer)) }
        attr_reader :offset

        sig { returns(T.nilable(String)) }
        attr_reader :timezone

        sig { returns(T.nilable(T::Boolean)) }
        attr_reader :ephemeral

        sig { returns(T.nilable(T::Boolean)) }
        attr_reader :visible

        sig { returns(T.nilable(String)) }
        attr_reader :requested_by

        sig { returns(T.nilable(String)) }
        attr_reader :query_id

        sig { returns(T.nilable(T::Boolean)) }
        attr_reader :cache

        sig do
          params(
            statement: String,
            catalog: T.nilable(String),
            schema: T.nilable(String),
            session_id: T.nilable(String),
            compute_size: T.nilable(String),
            sanitize: T.nilable(T::Boolean),
            limit: T.nilable(Integer),
            offset: T.nilable(Integer),
            timezone: T.nilable(String),
            ephemeral: T.nilable(T::Boolean),
            visible: T.nilable(T::Boolean),
            requested_by: T.nilable(String),
            query_id: T.nilable(String),
            cache: T.nilable(T::Boolean)
          ).void
        end
        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, compute_size: nil, sanitize: nil, limit: nil, offset: nil, timezone: nil, ephemeral: nil, visible: nil, requested_by: nil, query_id: nil, cache: nil); end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def to_h; end
      end

      class ValidateRequest < Request
        sig { returns(String) }
        attr_reader :statement

        sig { returns(T.nilable(String)) }
        attr_reader :catalog

        sig { returns(T.nilable(String)) }
        attr_reader :schema

        sig { returns(T.nilable(String)) }
        attr_reader :session_id

        sig do
          params(
            statement: String,
            catalog: T.nilable(String),
            schema: T.nilable(String),
            session_id: T.nilable(String)
          ).void
        end
        def initialize(statement:, catalog: nil, schema: nil, session_id: nil); end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def to_h; end
      end

      class ValidateResponse < Request
        sig { returns(T::Boolean) }
        attr_reader :valid

        sig { returns(String) }
        attr_reader :statement

        sig { returns(T.untyped) }
        attr_reader :connections_errors

        sig { returns(T.untyped) }
        attr_reader :error

        sig do
          params(
            valid: T::Boolean,
            statement: String,
            connections_errors: T.untyped,
            error: T.untyped
          ).void
        end
        def initialize(valid:, statement:, connections_errors: nil, error: nil); end

        sig { params(h: T::Hash[String, T.untyped]).returns(ValidateResponse) }
        def self.from_h(h); end
      end

      class QueryLogResponse < Request
        sig { returns(String) }
        attr_reader :uuid

        sig { returns(String) }
        attr_reader :start_time

        sig { returns(String) }
        attr_reader :end_time

        sig { returns(Integer) }
        attr_reader :duration_ms

        sig { returns(String) }
        attr_reader :query

        sig { returns(String) }
        attr_reader :session_id

        sig { returns(String) }
        attr_reader :client_interface

        sig { returns(T.untyped) }
        attr_reader :error

        sig { returns(T.untyped) }
        attr_reader :stats

        sig { returns(T.untyped) }
        attr_reader :progress

        sig { returns(T::Boolean) }
        attr_reader :visible

        sig { returns(String) }
        attr_reader :requested_by

        sig { returns(String) }
        attr_reader :user_agent

        sig do
          params(
            uuid: String,
            start_time: String,
            end_time: String,
            duration_ms: Integer,
            query: String,
            session_id: String,
            client_interface: String,
            error: T.untyped,
            stats: T.untyped,
            progress: T.untyped,
            visible: T::Boolean,
            requested_by: String,
            user_agent: String
          ).void
        end
        def initialize(uuid:, start_time:, end_time:, duration_ms:, query:, session_id:, client_interface:, error:, stats:, progress:, visible:, requested_by:, user_agent:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(QueryLogResponse) }
        def self.from_h(h); end
      end

      class CancelQueryResponse < Request
        sig { returns(T::Boolean) }
        attr_reader :cancelled

        sig { returns(String) }
        attr_reader :message

        sig { params(cancelled: T::Boolean, message: String).void }
        def initialize(cancelled:, message:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(CancelQueryResponse) }
        def self.from_h(h); end
      end

      class AutocompleteRequest < Request
        sig { returns(String) }
        attr_reader :statement

        sig { returns(T.nilable(String)) }
        attr_reader :catalog

        sig { returns(T.nilable(String)) }
        attr_reader :schema

        sig { returns(T.nilable(String)) }
        attr_reader :session_id

        sig { returns(T.nilable(Integer)) }
        attr_reader :max_suggestions

        sig do
          params(
            statement: String,
            catalog: T.nilable(String),
            schema: T.nilable(String),
            session_id: T.nilable(String),
            max_suggestions: T.nilable(Integer)
          ).void
        end
        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, max_suggestions: nil); end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def to_h; end
      end

      class AutocompleteSuggestion < Request
        sig { returns(String) }
        attr_reader :suggestion

        sig { returns(Integer) }
        attr_reader :suggestion_start

        sig { returns(String) }
        attr_reader :suggestion_type

        sig { returns(T.any(Integer, Float)) }
        attr_reader :suggestion_score

        sig { returns(T.nilable(String)) }
        attr_reader :extra_char

        sig do
          params(
            suggestion: String,
            suggestion_start: Integer,
            suggestion_type: String,
            suggestion_score: T.any(Integer, Float),
            extra_char: T.nilable(String)
          ).void
        end
        def initialize(suggestion:, suggestion_start:, suggestion_type:, suggestion_score:, extra_char: nil); end

        sig { params(h: T::Hash[String, T.untyped]).returns(AutocompleteSuggestion) }
        def self.from_h(h); end
      end

      class AutocompleteResponse < Request
        sig { returns(T::Array[AutocompleteSuggestion]) }
        attr_reader :suggestions

        sig { returns(String) }
        attr_reader :statement

        sig { returns(T::Hash[T.untyped, T.untyped]) }
        attr_reader :connections_errors

        sig do
          params(
            suggestions: T::Array[AutocompleteSuggestion],
            statement: String,
            connections_errors: T::Hash[T.untyped, T.untyped]
          ).void
        end
        def initialize(suggestions:, statement:, connections_errors:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(AutocompleteResponse) }
        def self.from_h(h); end
      end
    end

    module Adapters
      class Response
        sig { returns(Integer) }
        attr_reader :status

        sig { returns(T.nilable(String)) }
        attr_reader :body

        sig { returns(T::Hash[String, T.untyped]) }
        attr_reader :headers

        sig { params(status: Integer, body: T.nilable(String), headers: T::Hash[String, T.untyped]).void }
        def initialize(status, body = nil, headers = {}); end
      end

      class Base
        sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T::Hash[String, String]).void }
        def initialize(base_url:, timeout:, headers: {}); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end
      end

      class FaradayAdapter < Base
        sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T::Hash[String, String]).void }
        def initialize(base_url:, timeout:, headers: {}); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end

        private

        sig { params(resp: T.untyped).returns(Response) }
        def wrap_response(resp); end
      end

      class HttpxAdapter < Base
        sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T::Hash[String, String]).void }
        def initialize(base_url:, timeout:, headers: {}); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end

        private

        sig { params(resp: T.untyped).returns(Response) }
        def wrap_response(resp); end
      end

      class NetHttpAdapter < Base
        sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T::Hash[String, String]).void }
        def initialize(base_url:, timeout:, headers: {}); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end

        private

        sig do
          params(
            klass: T.untyped,
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(Response)
        end
        def request(klass, path, body: nil, params: {}, headers: {}, &block); end
      end
    end
  end
end
