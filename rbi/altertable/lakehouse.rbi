# typed: true

module Altertable
  module Lakehouse
    VERSION = T.let(T.unsafe(nil), String)

    class Error < StandardError
      sig { returns(T.nilable(String)) }
      def operation; end

      sig { returns(T.nilable(String)) }
      def http_method; end

      sig { returns(T.nilable(String)) }
      def http_path; end

      sig { returns(T.nilable(Integer)) }
      def status_code; end

      sig { returns(T::Boolean) }
      def retriable; end

      sig { returns(T.nilable(String)) }
      def request_id; end

      sig { returns(T.nilable(Exception)) }
      def cause; end

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
          adapter: T.nilable(Symbol),
          headers: T::Hash[String, String]
        ).void
      end
      def initialize(username: nil, password: nil, basic_auth_token: nil, base_url: nil, timeout: nil, user_agent: nil, adapter: nil, headers: {}); end

      sig do
        params(
          catalog: String,
          schema: String,
          table: String,
          payload: T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]]),
          sync: T.nilable(T::Boolean),
          headers: T::Hash[String, String]
        ).returns(::Altertable::Lakehouse::Models::AppendResponse)
      end
      def append(catalog:, schema:, table:, payload:, sync: nil, headers: {}); end

      sig { params(task_id: String, headers: T::Hash[String, String]).returns(::Altertable::Lakehouse::Models::TaskResponse) }
      def get_task(task_id, headers: {}); end

      sig { params(statement: String, headers: T::Hash[String, String], options: T.untyped).returns(::Altertable::Lakehouse::QueryResult) }
      def query(statement:, headers: {}, **options); end

      sig { params(statement: String, headers: T::Hash[String, String], options: T.untyped).returns(T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
      def query_all(statement:, headers: {}, **options); end

      sig do
        params(
          catalog: String,
          schema: String,
          table: String,
          format: String,
          mode: String,
          file_io: T.untyped,
          primary_key: T.nilable(String),
          headers: T::Hash[String, String]
        ).returns(T.untyped)
      end
      def upload(catalog:, schema:, table:, format:, mode:, file_io:, primary_key: nil, headers: {}); end

      sig { params(query_id: String, headers: T::Hash[String, String]).returns(::Altertable::Lakehouse::Models::QueryLogResponse) }
      def get_query(query_id, headers: {}); end

      sig { params(query_id: String, session_id: String, headers: T::Hash[String, String]).returns(::Altertable::Lakehouse::Models::CancelQueryResponse) }
      def cancel_query(query_id, session_id:, headers: {}); end

      sig do
        params(
          statement: String,
          catalog: T.nilable(String),
          schema: T.nilable(String),
          session_id: T.nilable(String),
          headers: T::Hash[String, String]
        ).returns(::Altertable::Lakehouse::Models::ValidateResponse)
      end
      def validate(statement:, catalog: nil, schema: nil, session_id: nil, headers: {}); end

      sig do
        params(
          statement: String,
          catalog: T.nilable(String),
          schema: T.nilable(String),
          session_id: T.nilable(String),
          max_suggestions: T.nilable(Integer),
          headers: T::Hash[String, String]
        ).returns(::Altertable::Lakehouse::Models::AutocompleteResponse)
      end
      def autocomplete(statement:, catalog: nil, schema: nil, session_id: nil, max_suggestions: nil, headers: {}); end

      sig do
        params(
          statement: String,
          catalog: T.nilable(String),
          schema: T.nilable(String),
          session_id: T.nilable(String),
          include_plan: T.nilable(T::Boolean),
          headers: T::Hash[String, String]
        ).returns(::Altertable::Lakehouse::Models::ExplainResponse)
      end
      def explain(statement:, catalog: nil, schema: nil, session_id: nil, include_plan: nil, headers: {}); end

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
          query: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]),
          headers: T::Hash[String, String]
        ).returns(T.untyped)
      end
      def request(method, path, body: nil, query: nil, headers: {}); end

      sig { params(resp: ::Altertable::Lakehouse::Adapters::Response, buffer: String, yielder: Enumerator::Yielder).void }
      def handle_stream_response(resp, buffer, yielder); end

      sig { params(resp: ::Altertable::Lakehouse::Adapters::Response).returns(T.untyped) }
      def handle_response(resp); end
    end

    class QueryResult
      include Enumerable

      sig { returns(T.untyped) }
      def metadata; end

      sig { returns(T.untyped) }
      def columns; end

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
        def payload; end

        sig { params(payload: T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]])).void }
        def initialize(payload); end

        sig { returns(T.any(T::Hash[T.untyped, T.untyped], T::Array[T::Hash[T.untyped, T.untyped]])) }
        def to_h; end
      end

      class AppendResponse < Request
        sig { returns(T::Boolean) }
        def ok; end

        sig { returns(T.nilable(String)) }
        def error_code; end

        sig { returns(T.nilable(String)) }
        def error_message; end

        sig { returns(T.nilable(String)) }
        def task_id; end

        sig do
          params(
            ok: T::Boolean,
            error_code: T.nilable(String),
            error_message: T.nilable(String),
            task_id: T.nilable(String)
          ).void
        end
        def initialize(ok:, error_code: nil, error_message: nil, task_id: nil); end

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::AppendResponse) }
        def self.from_h(h); end
      end

      class TaskResponse < Request
        sig { returns(String) }
        def task_id; end

        sig { returns(String) }
        def status; end

        sig { params(task_id: String, status: String).void }
        def initialize(task_id:, status:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::TaskResponse) }
        def self.from_h(h); end
      end

      class QueryRequest < Request
        sig { returns(String) }
        def statement; end

        sig { returns(T.nilable(String)) }
        def catalog; end

        sig { returns(T.nilable(String)) }
        def schema; end

        sig { returns(T.nilable(String)) }
        def session_id; end

        sig { returns(T.nilable(String)) }
        def compute_size; end

        sig { returns(T.nilable(T::Boolean)) }
        def sanitize; end

        sig { returns(T.nilable(Integer)) }
        def limit; end

        sig { returns(T.nilable(Integer)) }
        def offset; end

        sig { returns(T.nilable(String)) }
        def timezone; end

        sig { returns(T.nilable(T::Boolean)) }
        def ephemeral; end

        sig { returns(T.nilable(T::Boolean)) }
        def visible; end

        sig { returns(T.nilable(String)) }
        def requested_by; end

        sig { returns(T.nilable(String)) }
        def query_id; end

        sig { returns(T.nilable(T::Boolean)) }
        def cache; end

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
        def statement; end

        sig { returns(T.nilable(String)) }
        def catalog; end

        sig { returns(T.nilable(String)) }
        def schema; end

        sig { returns(T.nilable(String)) }
        def session_id; end

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
        def valid; end

        sig { returns(String) }
        def statement; end

        sig { returns(T.untyped) }
        def connections_errors; end

        sig { returns(T.untyped) }
        def error; end

        sig do
          params(
            valid: T::Boolean,
            statement: String,
            connections_errors: T.untyped,
            error: T.untyped
          ).void
        end
        def initialize(valid:, statement:, connections_errors: nil, error: nil); end

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::ValidateResponse) }
        def self.from_h(h); end
      end

      class QueryLogResponse < Request
        sig { returns(String) }
        def uuid; end

        sig { returns(String) }
        def start_time; end

        sig { returns(String) }
        def end_time; end

        sig { returns(Integer) }
        def duration_ms; end

        sig { returns(String) }
        def query; end

        sig { returns(String) }
        def session_id; end

        sig { returns(String) }
        def client_interface; end

        sig { returns(T.untyped) }
        def error; end

        sig { returns(T.untyped) }
        def stats; end

        sig { returns(T.untyped) }
        def progress; end

        sig { returns(T::Boolean) }
        def visible; end

        sig { returns(String) }
        def requested_by; end

        sig { returns(String) }
        def user_agent; end

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

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::QueryLogResponse) }
        def self.from_h(h); end
      end

      class CancelQueryResponse < Request
        sig { returns(T::Boolean) }
        def cancelled; end

        sig { returns(String) }
        def message; end

        sig { params(cancelled: T::Boolean, message: String).void }
        def initialize(cancelled:, message:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::CancelQueryResponse) }
        def self.from_h(h); end
      end

      class AutocompleteRequest < Request
        sig { returns(String) }
        def statement; end

        sig { returns(T.nilable(String)) }
        def catalog; end

        sig { returns(T.nilable(String)) }
        def schema; end

        sig { returns(T.nilable(String)) }
        def session_id; end

        sig { returns(T.nilable(Integer)) }
        def max_suggestions; end

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
        def suggestion; end

        sig { returns(Integer) }
        def suggestion_start; end

        sig { returns(String) }
        def suggestion_type; end

        sig { returns(T.any(Integer, Float)) }
        def suggestion_score; end

        sig { returns(T.nilable(String)) }
        def extra_char; end

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

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::AutocompleteSuggestion) }
        def self.from_h(h); end
      end

      class AutocompleteResponse < Request
        sig { returns(T::Array[::Altertable::Lakehouse::Models::AutocompleteSuggestion]) }
        def suggestions; end

        sig { returns(String) }
        def statement; end

        sig { returns(T::Hash[T.untyped, T.untyped]) }
        def connections_errors; end

        sig do
          params(
            suggestions: T::Array[::Altertable::Lakehouse::Models::AutocompleteSuggestion],
            statement: String,
            connections_errors: T::Hash[T.untyped, T.untyped]
          ).void
        end
        def initialize(suggestions:, statement:, connections_errors:); end

        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::AutocompleteResponse) }
        def self.from_h(h); end
      end

      class ExplainRequest < Request
        sig { returns(String) }
        def statement; end

        sig { returns(T.nilable(String)) }
        def catalog; end

        sig { returns(T.nilable(String)) }
        def schema; end

        sig { returns(T.nilable(String)) }
        def session_id; end

        sig { returns(T.nilable(T::Boolean)) }
        def include_plan; end

        sig do
          params(
            statement: String,
            catalog: T.nilable(String),
            schema: T.nilable(String),
            session_id: T.nilable(String),
            include_plan: T.nilable(T::Boolean)
          ).void
        end
        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, include_plan: nil); end

        sig { returns(T::Hash[Symbol, T.untyped]) }
        def to_h; end
      end

      class TableScanEstimate < Request
        sig { returns(String) }
        def table_name; end

        sig { returns(Integer) }
        def estimated_rows; end

        sig { returns(T.nilable(String)) }
        def filters; end

        sig { returns(T.nilable(Integer)) }
        def scanned_bytes_estimate; end

        sig { returns(T.nilable(Integer)) }
        def scanned_files_estimate; end

        sig { returns(T.nilable(Integer)) }
        def total_bytes; end

        sig { returns(T.nilable(Integer)) }
        def total_files; end

        sig do
          params(
            table_name: String,
            estimated_rows: Integer,
            filters: T.nilable(String),
            scanned_bytes_estimate: T.nilable(Integer),
            scanned_files_estimate: T.nilable(Integer),
            total_bytes: T.nilable(Integer),
            total_files: T.nilable(Integer)
          ).void
        end
        def initialize(table_name:, estimated_rows:, filters: nil, scanned_bytes_estimate: nil,
                       scanned_files_estimate: nil, total_bytes: nil, total_files: nil) 
        end
        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::TableScanEstimate) }
        def self.from_h(h); end
      end

      class ExplainResponse < Request
        sig { returns(T::Array[::Altertable::Lakehouse::Models::TableScanEstimate]) }
        def tables; end

        sig { returns(String) }
        def statement; end

        sig { returns(T::Hash[T.untyped, T.untyped]) }
        def connections_errors; end

        sig { returns(T.nilable(String)) }
        def error; end

        sig { returns(T.untyped) }
        def plan; end

        sig { returns(T.nilable(Integer)) }
        def scanned_bytes_estimate; end

        sig { returns(T.nilable(Integer)) }
        def scanned_files_estimate; end

        sig { returns(T.nilable(Integer)) }
        def total_bytes; end

        sig { returns(T.nilable(Integer)) }
        def total_files; end

        sig do
          params(
            tables: T::Array[::Altertable::Lakehouse::Models::TableScanEstimate],
            statement: String,
            connections_errors: T::Hash[T.untyped, T.untyped],
            error: T.nilable(String),
            plan: T.untyped,
            scanned_bytes_estimate: T.nilable(Integer),
            scanned_files_estimate: T.nilable(Integer),
            total_bytes: T.nilable(Integer),
            total_files: T.nilable(Integer)
          ).void
        end
        def initialize(tables:, statement:, connections_errors:, error: nil, plan: nil,
                       scanned_bytes_estimate: nil, scanned_files_estimate: nil,
                       total_bytes: nil, total_files: nil) 
        end
        sig { params(h: T::Hash[String, T.untyped]).returns(::Altertable::Lakehouse::Models::ExplainResponse) }
        def self.from_h(h); end
      end
    end

    module Adapters
      class Response
        sig { returns(Integer) }
        def status; end

        sig { returns(T.nilable(String)) }
        def body; end

        sig { returns(T::Hash[String, T.untyped]) }
        def headers; end

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
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
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
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end

        private

        sig { params(resp: T.untyped).returns(::Altertable::Lakehouse::Adapters::Response) }
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
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def delete(path, body: nil, params: {}, headers: {}, &block); end

        private

        sig { params(resp: T.untyped).returns(::Altertable::Lakehouse::Adapters::Response) }
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
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def get(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def post(path, body: nil, params: {}, headers: {}, &block); end

        sig do
          params(
            path: String,
            body: T.nilable(String),
            params: T::Hash[T.any(Symbol, String), T.untyped],
            headers: T::Hash[String, String],
            block: T.nilable(T.proc.params(arg0: T.untyped, arg1: T.untyped).void)
          ).returns(::Altertable::Lakehouse::Adapters::Response)
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
          ).returns(::Altertable::Lakehouse::Adapters::Response)
        end
        def request(klass, path, body: nil, params: {}, headers: {}, &block); end
      end
    end
  end
end
