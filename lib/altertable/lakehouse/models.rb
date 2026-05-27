module Altertable
  module Lakehouse
    module Models
      class Request
        def to_h
          raise NotImplementedError
        end
      end

      class AppendRequest < Request
        attr_reader :payload

        # Payload can be a single Hash or an Array of Hashes
        def initialize(payload)
          @payload = payload
        end

        def to_h
          @payload
        end
      end

      class AppendResponse < Request
        attr_reader :ok, :error_code, :error_message, :task_id

        def initialize(ok:, error_code: nil, error_message: nil, task_id: nil)
          @ok = ok
          @error_code = error_code
          @error_message = error_message
          @task_id = task_id
        end

        def self.from_h(h)
          new(
            ok: h["ok"],
            error_code: h["error_code"],
            error_message: h["error_message"],
            task_id: h["task_id"]
          )
        end
      end

      class TaskResponse < Request
        attr_reader :task_id, :status

        def initialize(task_id:, status:)
          @task_id = task_id
          @status = status
        end

        def self.from_h(h)
          new(task_id: h["task_id"], status: h["status"])
        end
      end

      class QueryRequest < Request
        attr_reader :statement, :catalog, :schema, :session_id, :compute_size, :sanitize, :limit, :offset, :timezone, :ephemeral, :visible, :requested_by, :query_id, :cache

        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, compute_size: nil, sanitize: nil, limit: nil, offset: nil, timezone: nil, ephemeral: nil, visible: nil, requested_by: nil, query_id: nil, cache: nil)
          @statement = statement
          @catalog = catalog
          @schema = schema
          @session_id = session_id
          @compute_size = compute_size
          @sanitize = sanitize
          @limit = limit
          @offset = offset
          @timezone = timezone
          @ephemeral = ephemeral
          @visible = visible
          @requested_by = requested_by
          @query_id = query_id
          @cache = cache
        end

        def to_h
          h = { statement: @statement }
          h[:catalog] = @catalog if @catalog
          h[:schema] = @schema if @schema
          h[:session_id] = @session_id if @session_id
          h[:compute_size] = @compute_size if @compute_size
          h[:sanitize] = @sanitize unless @sanitize.nil?
          h[:limit] = @limit if @limit
          h[:offset] = @offset if @offset
          h[:timezone] = @timezone if @timezone
          h[:ephemeral] = @ephemeral unless @ephemeral.nil?
          h[:visible] = @visible unless @visible.nil?
          h[:requested_by] = @requested_by if @requested_by
          h[:query_id] = @query_id if @query_id
          h[:cache] = @cache unless @cache.nil?
          h
        end
      end

      class ValidateRequest < Request
        attr_reader :statement, :catalog, :schema, :session_id

        def initialize(statement:, catalog: nil, schema: nil, session_id: nil)
          @statement = statement
          @catalog = catalog
          @schema = schema
          @session_id = session_id
        end

        def to_h
          h = { statement: @statement }
          h[:catalog] = @catalog if @catalog
          h[:schema] = @schema if @schema
          h[:session_id] = @session_id if @session_id
          h
        end
      end

      class ValidateResponse < Request
        attr_reader :valid, :statement, :connections_errors, :error

        def initialize(valid:, statement:, connections_errors: nil, error: nil)
          @valid = valid
          @statement = statement
          @connections_errors = connections_errors
          @error = error
        end

        def self.from_h(h)
          new(
            valid: h["valid"],
            statement: h["statement"],
            connections_errors: h["connections_errors"],
            error: h["error"]
          )
        end
      end
      
      class QueryLogResponse < Request
        attr_reader :uuid, :start_time, :end_time, :duration_ms, :query, :session_id, :client_interface, :error, :stats, :progress, :visible, :requested_by, :user_agent

        def initialize(uuid:, start_time:, end_time:, duration_ms:, query:, session_id:, client_interface:, error:, stats:, progress:, visible:, requested_by:, user_agent:)
          @uuid = uuid
          @start_time = start_time
          @end_time = end_time
          @duration_ms = duration_ms
          @query = query
          @session_id = session_id
          @client_interface = client_interface
          @error = error
          @stats = stats
          @progress = progress
          @visible = visible
          @requested_by = requested_by
          @user_agent = user_agent
        end
        
        def self.from_h(h)
           new(
             uuid: h["uuid"],
             start_time: h["start_time"],
             end_time: h["end_time"],
             duration_ms: h["duration_ms"],
             query: h["query"],
             session_id: h["session_id"],
             client_interface: h["client_interface"],
             error: h["error"],
             stats: h["stats"],
             progress: h["progress"],
             visible: h["visible"],
             requested_by: h["requested_by"],
             user_agent: h["user_agent"]
           )
        end
      end

      class CancelQueryResponse < Request
        attr_reader :cancelled, :message

        def initialize(cancelled:, message:)
          @cancelled = cancelled
          @message = message
        end
        
        def self.from_h(h)
          new(cancelled: h["cancelled"], message: h["message"])
        end
      end

      class AutocompleteRequest < Request
        attr_reader :statement, :catalog, :schema, :session_id, :max_suggestions

        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, max_suggestions: nil)
          @statement = statement
          @catalog = catalog
          @schema = schema
          @session_id = session_id
          @max_suggestions = max_suggestions
        end

        def to_h
          h = { statement: @statement }
          h[:catalog] = @catalog if @catalog
          h[:schema] = @schema if @schema
          h[:session_id] = @session_id if @session_id
          h[:max_suggestions] = @max_suggestions if @max_suggestions
          h
        end
      end

      class AutocompleteSuggestion < Request
        attr_reader :suggestion, :suggestion_start, :suggestion_type, :suggestion_score, :extra_char

        def initialize(suggestion:, suggestion_start:, suggestion_type:, suggestion_score:, extra_char: nil)
          @suggestion = suggestion
          @suggestion_start = suggestion_start
          @suggestion_type = suggestion_type
          @suggestion_score = suggestion_score
          @extra_char = extra_char
        end

        def self.from_h(h)
          new(
            suggestion: h["suggestion"],
            suggestion_start: h["suggestion_start"],
            suggestion_type: h["suggestion_type"],
            suggestion_score: h["suggestion_score"],
            extra_char: h["extra_char"]
          )
        end
      end

      class AutocompleteResponse < Request
        attr_reader :suggestions, :statement, :connections_errors

        def initialize(suggestions:, statement:, connections_errors:)
          @suggestions = suggestions
          @statement = statement
          @connections_errors = connections_errors
        end

        def self.from_h(h)
          new(
            suggestions: Array(h["suggestions"]).map { |suggestion| AutocompleteSuggestion.from_h(suggestion) },
            statement: h["statement"],
            connections_errors: h["connections_errors"] || {}
          )
        end
      end

      class ExplainRequest < Request
        attr_reader :statement, :catalog, :schema, :session_id, :include_plan

        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, include_plan: nil)
          @statement = statement
          @catalog = catalog
          @schema = schema
          @session_id = session_id
          @include_plan = include_plan
        end

        def to_h
          h = { statement: @statement }
          h[:catalog] = @catalog if @catalog
          h[:schema] = @schema if @schema
          h[:session_id] = @session_id if @session_id
          h[:include_plan] = @include_plan unless @include_plan.nil?
          h
        end
      end

      class TableScanEstimate < Request
        attr_reader :table_name, :estimated_rows, :filters, :scanned_bytes_estimate,
                    :scanned_files_estimate, :total_bytes, :total_files

        def initialize(table_name:, estimated_rows:, filters: nil, scanned_bytes_estimate: nil,
                       scanned_files_estimate: nil, total_bytes: nil, total_files: nil)
          @table_name = table_name
          @estimated_rows = estimated_rows
          @filters = filters
          @scanned_bytes_estimate = scanned_bytes_estimate
          @scanned_files_estimate = scanned_files_estimate
          @total_bytes = total_bytes
          @total_files = total_files
        end

        def self.from_h(h)
          new(
            table_name: h["table_name"],
            estimated_rows: h["estimated_rows"],
            filters: h["filters"],
            scanned_bytes_estimate: h["scanned_bytes_estimate"],
            scanned_files_estimate: h["scanned_files_estimate"],
            total_bytes: h["total_bytes"],
            total_files: h["total_files"]
          )
        end
      end

      class ExplainResponse < Request
        attr_reader :tables, :statement, :connections_errors, :error, :plan,
                    :scanned_bytes_estimate, :scanned_files_estimate, :total_bytes, :total_files

        def initialize(tables:, statement:, connections_errors:, error: nil, plan: nil,
                       scanned_bytes_estimate: nil, scanned_files_estimate: nil,
                       total_bytes: nil, total_files: nil)
          @tables = tables
          @statement = statement
          @connections_errors = connections_errors
          @error = error
          @plan = plan
          @scanned_bytes_estimate = scanned_bytes_estimate
          @scanned_files_estimate = scanned_files_estimate
          @total_bytes = total_bytes
          @total_files = total_files
        end

        def self.from_h(h)
          new(
            tables: Array(h["tables"]).map { |table| TableScanEstimate.from_h(table) },
            statement: h["statement"],
            connections_errors: h["connections_errors"] || {},
            error: h["error"],
            plan: h["plan"],
            scanned_bytes_estimate: h["scanned_bytes_estimate"],
            scanned_files_estimate: h["scanned_files_estimate"],
            total_bytes: h["total_bytes"],
            total_files: h["total_files"]
          )
        end
      end
    end
  end
end
