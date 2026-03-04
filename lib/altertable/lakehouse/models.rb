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
        attr_reader :ok, :error_code

        def initialize(ok:, error_code: nil)
          @ok = ok
          @error_code = error_code
        end

        def self.from_h(h)
          new(ok: h["ok"], error_code: h["error_code"])
        end
      end

      class QueryRequest < Request
        attr_reader :statement, :catalog, :schema, :session_id, :compute_size, :sanitize, :limit, :offset, :timezone, :ephemeral, :visible, :requested_by, :query_id

        def initialize(statement:, catalog: nil, schema: nil, session_id: nil, compute_size: nil, sanitize: nil, limit: nil, offset: nil, timezone: nil, ephemeral: nil, visible: nil, requested_by: nil, query_id: nil)
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
          h
        end
      end

      class ValidateRequest < Request
        attr_reader :statement

        def initialize(statement:)
          @statement = statement
        end

        def to_h
          { statement: @statement }
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
    end
  end
end
