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
  end

  # ── #append ──────────────────────────────────────────────────────────────────

  describe "#append" do
    it "appends a row and returns ok: true" do
      # Ensure the table exists first via upload (CSV create)
      csv = "user_id,name\n1,Alice\n"
      client.upload(
        catalog: "memory",
        schema: "main",
        table: "append_events",
        format: "csv",
        mode: "create",
        file_io: StringIO.new(csv)
      )

      resp = client.append(
        catalog: "memory",
        schema: "main",
        table: "append_events",
        payload: { user_id: 2, name: "Bob" }
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

  # ── #upload ──────────────────────────────────────────────────────────────────

  describe "#upload" do
    it "creates a table from CSV in create mode and allows querying it" do
      csv = "id,score\n10,100\n20,200\n"
      client.upload(
        catalog: "memory",
        schema: "main",
        table: "upload_test",
        format: "csv",
        mode: "create",
        file_io: StringIO.new(csv)
      )

      result = client.query_all(statement: "SELECT * FROM upload_test ORDER BY id")
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
end
