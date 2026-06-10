require "spec_helper"
require "base64"

# Integration tests against the altertable-mock container.
# Outside CI the container is started automatically via testcontainers (see
# spec/support/altertable_container.rb) and the mapped port is stored in
# ALTERTABLE_MOCK_PORT.  In CI the service is pre-bound to 15000.
MOCK_BASE_URL = "http://localhost:#{ENV.fetch("ALTERTABLE_MOCK_PORT", 15000)}"
MOCK_USERNAME = "testuser"
MOCK_PASSWORD = "testpass"

RSpec.describe Altertable::Lakehouse::Client do
  let(:basic_token) { Base64.strict_encode64("#{MOCK_USERNAME}:#{MOCK_PASSWORD}") }
  let(:client) do
    described_class.new(
      username: MOCK_USERNAME,
      password: MOCK_PASSWORD,
      base_url: MOCK_BASE_URL
    )
  end

  # ── #initialize ──────────────────────────────────────────────────────────────

  describe "#initialize" do
    it "sets Basic auth header with username/password" do
      c = described_class.new(username: "u", password: "p", base_url: MOCK_BASE_URL)
      expect(c.instance_variable_get(:@auth_header)).to eq("Basic #{Base64.strict_encode64("u:p")}")
    end

    it "sets Basic auth header with basic_auth_token" do
      c = described_class.new(basic_auth_token: "pre-encoded", base_url: MOCK_BASE_URL)
      expect(c.instance_variable_get(:@auth_header)).to eq("Basic pre-encoded")
    end

    it "raises ConfigurationError if no credentials" do
      expect { described_class.new }.to raise_error(Altertable::Lakehouse::ConfigurationError)
    end

    it "merges custom headers into the adapter defaults" do
      c = described_class.new(
        username: "u",
        password: "p",
        base_url: MOCK_BASE_URL,
        headers: { "X-Tenant" => "acme" }
      )
      adapter = c.instance_variable_get(:@adapter)
      expect(adapter.instance_variable_get(:@headers)).to include("X-Tenant" => "acme")
      expect(adapter.instance_variable_get(:@headers)).not_to include("Content-Type")
    end
  end

  # ── #append ──────────────────────────────────────────────────────────────────

  describe "#append" do
    it "appends a row and returns ok: true" do
      table_name = "append_events_#{SecureRandom.hex(4)}"

      # Ensure the table exists first via upsert (CSV create)
      csv = "user_id,name\n1,Alice\n"
      client.upsert(
        catalog: "memory",
        schema: "main",
        table: table_name,
        mode: "create",
        file_io: StringIO.new(csv)
      )

      resp = client.append(
        catalog: "memory",
        schema: "main",
        table: table_name,
        payload: { user_id: 2, name: "Bob" }
      )
      expect(resp.ok).to be true
    end

    it "appends an array of rows and returns ok: true" do
      table_name = "append_events_batch_#{SecureRandom.hex(4)}"

      csv = "user_id,name\n1,Alice\n"
      client.upsert(
        catalog: "memory",
        schema: "main",
        table: table_name,
        mode: "create",
        file_io: StringIO.new(csv)
      )

      resp = client.append(
        catalog: "memory",
        schema: "main",
        table: table_name,
        payload: [
          { user_id: 2, name: "Bob" },
          { user_id: 3, name: "Carol" }
        ]
      )
      expect(resp.ok).to be true

      result = client.query_all(statement: "SELECT * FROM #{table_name} ORDER BY user_id")
      expect(result[:rows]).to eq([
        { "user_id" => 1, "name" => "Alice" },
        { "user_id" => 2, "name" => "Bob" },
        { "user_id" => 3, "name" => "Carol" }
      ])
    end

    it "supports the sync query parameter" do
      table_name = "append_events_sync_#{SecureRandom.hex(4)}"

      csv = "user_id,name\n1,Alice\n"
      client.upsert(
        catalog: "memory",
        schema: "main",
        table: table_name,
        mode: "create",
        file_io: StringIO.new(csv)
      )

      resp = client.append(
        catalog: "memory",
        schema: "main",
        table: table_name,
        payload: { user_id: 2, name: "Bob" },
        sync: true
      )

      expect(resp.ok).to be true
    end

    it "raises AuthError when credentials are wrong" do
      bad_client = described_class.new(
        username: "baduser",
        password: "badpass",
        base_url: MOCK_BASE_URL
      )
      expect {
        bad_client.append(catalog: "memory", schema: "main", table: "t", payload: {})
      }.to raise_error(Altertable::Lakehouse::AuthError)
    end
  end

  # ── #query ───────────────────────────────────────────────────────────────────

  describe "#query (streaming)" do
    it "parses the header, column names and data rows from a SELECT" do
      result = client.query(statement: "SELECT 42 AS answer")
      rows = result.to_a

      expect(result.metadata).to be_a(Hash)
      expect(result.metadata["statement"]).to eq("SELECT 42 AS answer")
      expect(result.columns).to eq(["answer"])
      expect(rows.length).to eq(1)
      expect(rows[0]).to eq({ "answer" => 42 })
    end

    it "returns multiple rows in correct order" do
      result = client.query(
        statement: "SELECT * FROM (VALUES (1, 'a'), (2, 'b'), (3, 'c')) t(id, val)"
      )
      rows = result.to_a

      expect(result.columns).to eq(["id", "val"])
      expect(rows.length).to eq(3)
      expect(rows[0]).to eq({ "id" => 1, "val" => "a" })
      expect(rows[1]).to eq({ "id" => 2, "val" => "b" })
      expect(rows[2]).to eq({ "id" => 3, "val" => "c" })
    end

    it "returns an empty rows list for a zero-row query" do
      result = client.query(
        statement: "SELECT 1 AS n WHERE 1 = 0"
      )
      rows = result.to_a

      # The mock returns [] as the columns array when DuckDB produces no batches
      expect(result.columns).to eq([])
      expect(rows).to be_empty
    end
  end

  # ── #query_all ───────────────────────────────────────────────────────────────

  describe "#query_all" do
    it "accumulates metadata, columns, and rows" do
      result = client.query_all(
        statement: "SELECT 7 AS x, 'hello' AS y"
      )

      expect(result[:metadata]).to be_a(Hash)
      expect(result[:metadata]["statement"]).to eq("SELECT 7 AS x, 'hello' AS y")
      expect(result[:columns]).to eq(["x", "y"])
      expect(result[:rows]).to eq([{ "x" => 7, "y" => "hello" }])
    end

    it "forwards the cache option" do
      result = client.query_all(
        statement: "SELECT 1 AS cached_value",
        cache: true
      )

      expect(result[:rows]).to eq([{ "cached_value" => 1 }])
    end
  end

  # ── custom headers ───────────────────────────────────────────────────────────

  describe "custom headers" do
    let(:adapter) { client.instance_variable_get(:@adapter) }
    let(:ok_response) do
      Altertable::Lakehouse::Adapters::Response.new(200, { valid: true }.to_json, {})
    end

    it "forwards per-request headers on #validate" do
      expect(adapter).to receive(:post).with(
        "/validate",
        hash_including(headers: hash_including("Content-Type" => "application/json", "X-Request-Id" => "req-1"))
      ).and_return(ok_response)

      client.validate(statement: "SELECT 1", headers: { "X-Request-Id" => "req-1" })
    end

    it "forwards per-request headers on #query" do
      stream_response = Altertable::Lakehouse::Adapters::Response.new(
        200,
        "{\"statement\":\"SELECT 1\"}\n[\"n\"]\n[1]\n",
        {}
      )

      expect(adapter).to receive(:post).with(
        "/query",
        hash_including(headers: hash_including("Content-Type" => "application/json", "X-Trace" => "trace-1"))
      ).and_yield("{\"statement\":\"SELECT 1\"}\n", nil)
        .and_yield("[\"n\"]\n", nil)
        .and_yield("[1]\n", nil)
        .and_return(stream_response)

      client.query(statement: "SELECT 1", headers: { "X-Trace" => "trace-1" }).to_a
    end

    it "forwards per-request headers on #upsert without content type" do
      expect(adapter).to receive(:post).with(
        "/upsert",
        hash_including(
          headers: {
            "X-Upload-Source" => "etl"
          }
        )
      ).and_return(ok_response)

      client.upsert(
        catalog: "memory",
        schema: "main",
        table: "t",
        mode: "create",
        file_io: StringIO.new("id\n1\n"),
        headers: { "X-Upload-Source" => "etl" }
      )
    end
  end

  # ── error handling ───────────────────────────────────────────────────────────

  describe "error handling" do
    it "raises AuthError on 401" do
      bad_client = described_class.new(
        username: "nobody",
        password: "wrong",
        base_url: MOCK_BASE_URL
      )
      expect {
        bad_client.append(catalog: "a", schema: "b", table: "c", payload: {})
      }.to raise_error(Altertable::Lakehouse::AuthError)
    end

    it "raises BadRequestError on invalid SQL" do
      expect {
        client.query(statement: "INVALID SQL !!!").to_a
      }.to raise_error(Altertable::Lakehouse::BadRequestError)
    end
  end

  # ── #upsert ──────────────────────────────────────────────────────────────────

  describe "#upsert" do
    it "creates a table from CSV in create mode and allows querying it" do
      table_name = "upload_test_#{SecureRandom.hex(4)}"
      csv = "id,score\n10,100\n20,200\n"
      client.upsert(
        catalog: "memory",
        schema: "main",
        table: table_name,
        mode: "create",
        file_io: StringIO.new(csv)
      )

      result = client.query_all(statement: "SELECT * FROM #{table_name} ORDER BY id")
      expect(result[:columns]).to eq(["id", "score"])
      expect(result[:rows]).to eq([
        { "id" => 10, "score" => 100 },
        { "id" => 20, "score" => 200 }
      ])
    end
  end

  # ── #validate ────────────────────────────────────────────────────────────────

  describe "#validate" do
    it "returns valid: true for correct SQL" do
      resp = client.validate(statement: "SELECT 1")
      expect(resp.valid).to be true
      expect(resp.error).to be_nil
    end

    it "returns valid: false for invalid SQL" do
      resp = client.validate(statement: "NOT VALID SQL !!!")
      expect(resp.valid).to be false
      expect(resp.error).to be_a(String)
    end

    it "accepts optional request fields" do
      resp = client.validate(
        statement: "SELECT 1",
        catalog: "memory",
        schema: "main"
      )

      expect(resp.valid).to be true
    end
  end

  # ── #get_query ───────────────────────────────────────────────────────────────

  describe "#get_query" do
    it "returns the query log after a query is executed" do
      query_id = SecureRandom.uuid
      client.query(
        statement: "SELECT 1",
        query_id: query_id
      ).to_a

      log = client.get_query(query_id)
      expect(log.query).to eq("SELECT 1")
      expect(log.uuid).to eq(query_id)
    end
  end

  # ── #cancel_query ────────────────────────────────────────────────────────────

  describe "#cancel_query" do
    it "returns cancelled: false when session_id does not match" do
      query_id = SecureRandom.uuid
      session_id = SecureRandom.uuid

      client.query(
        statement: "SELECT 1",
        query_id: query_id,
        session_id: session_id
      ).to_a

      resp = client.cancel_query(query_id, session_id: "wrong-session")
      expect(resp.cancelled).to be false
    end

    it "returns cancelled: true when session_id matches" do
      query_id = SecureRandom.uuid
      session_id = SecureRandom.uuid

      client.query(
        statement: "SELECT 1",
        query_id: query_id,
        session_id: session_id
      ).to_a

      resp = client.cancel_query(query_id, session_id: session_id)
      expect(resp.cancelled).to be true
    end
  end

  # ── #get_task ───────────────────────────────────────────────────────────────

  describe "#get_task" do
    it "returns task status from the tasks endpoint" do
      adapter = client.instance_variable_get(:@adapter)
      response = Altertable::Lakehouse::Adapters::Response.new(
        200,
        { task_id: "task-123", status: "completed" }.to_json,
        {}
      )

      allow(adapter).to receive(:get).and_return(response)

      task = client.get_task("task-123")
      expect(task.task_id).to eq("task-123")
      expect(task.status).to eq("completed")
    end
  end

  # ── #explain ─────────────────────────────────────────────────────────────────
  # Mirrors altertable-mock lakehouse handlers POST /explain tests.

  describe "#explain" do
    it "returns no table scans for a simple SELECT" do
      resp = client.explain(statement: "SELECT 1")

      expect(resp.error).to be_nil
      expect(resp.tables).to eq([])
      expect(resp.statement).to eq("SELECT 1")
      expect(resp.connections_errors).to eq({})
    end

    it "returns table scan estimates for a filtered query" do
      table_name = "explain_events_#{SecureRandom.hex(4)}"
      client.query(
        statement: "CREATE TABLE #{table_name} (id INTEGER, category VARCHAR)"
      ).to_a
      client.query(
        statement: "INSERT INTO #{table_name} " \
                    "SELECT i, CASE WHEN i % 2 = 0 THEN 'even' ELSE 'odd' END " \
                    "FROM generate_series(1, 100) t(i)"
      ).to_a

      resp = client.explain(statement: "SELECT * FROM #{table_name} WHERE id > 50")

      expect(resp.error).to be_nil
      expect(resp.tables.length).to eq(1)
      expect(resp.tables.first.table_name).to end_with(table_name)
      expect(resp.tables.first.filters).to eq("id>50")
      expect(resp.tables.first.estimated_rows).to be > 0
    end

    it "returns an error in the body for invalid SQL" do
      resp = client.explain(statement: "NOT VALID SQL !!!")

      expect(resp.error).to be_a(String)
      expect(resp.tables).to eq([])
    end

    it "returns the EXPLAIN plan when include_plan is true" do
      resp = client.explain(statement: "SELECT 1", include_plan: true)

      expect(resp.error).to be_nil
      expect(resp.plan).to be_a(Array)
      expect(resp.plan.length).to eq(1)
      expect(resp.plan.first).to include("name")
    end

    it "accepts optional catalog and schema" do
      resp = client.explain(
        statement: "SELECT 1",
        catalog: "memory",
        schema: "main"
      )

      expect(resp.error).to be_nil
      expect(resp.tables).to eq([])
    end
  end

  # ── #autocomplete ───────────────────────────────────────────────────────────

  describe "#autocomplete" do
    it "returns autocomplete suggestions" do
      resp = client.autocomplete(statement: "SEL", max_suggestions: 5)

      expect(resp.statement).to eq("SEL")
      expect(resp.suggestions.length).to be <= 5
      expect(resp.suggestions).not_to be_empty
      expect(resp.suggestions.first.suggestion).to be_a(String)
    end
  end
end
