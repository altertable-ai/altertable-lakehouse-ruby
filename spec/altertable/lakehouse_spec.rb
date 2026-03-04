require "spec_helper"

RSpec.describe Altertable::Lakehouse::Client do
  let(:client) { described_class.new(api_key: "test-key") }
  let(:base_url) { "https://api.altertable.ai" }

  describe "#append" do
    it "sends correct request" do
      stub_request(:post, "#{base_url}/append")
        .with(
          query: { "catalog" => "main", "schema" => "public", "table" => "events" },
          body: { "user_id" => 123 },
          headers: { "Authorization" => "Bearer test-key", "Content-Type" => "application/json" }
        )
        .to_return(status: 200, body: { ok: true }.to_json)

      resp = client.append(catalog: "main", schema: "public", table: "events", payload: { user_id: 123 })
      expect(resp.ok).to be true
    end
  end

  describe "#query (streaming)" do
    it "parses streaming response correctly" do
      response_body = [
        { "metadata" => "some-meta" }.to_json,
        { "columns" => ["id", "val"] }.to_json,
        { "id" => 1, "val" => "a" }.to_json,
        { "id" => 2, "val" => "b" }.to_json
      ].join("\n")

      stub_request(:post, "#{base_url}/query")
        .with(body: { "statement" => "SELECT * FROM t" })
        .to_return(status: 200, body: response_body) # WebMock simulates full body unless streamed explicitly

      result = client.query(statement: "SELECT * FROM t")
      rows = result.to_a # Force iteration

      expect(result.metadata).to eq({ "metadata" => "some-meta" })
      expect(result.columns).to eq({ "columns" => ["id", "val"] })
      expect(rows.length).to eq(2)
      expect(rows[0]).to eq({ "id" => 1, "val" => "a" })
    end
  end

  describe "#query_all" do
    it "accumulates rows" do
      response_body = [
        { "metadata" => "m" }.to_json,
        { "columns" => ["c"] }.to_json,
        { "c" => 1 }.to_json
      ].join("\n")

      stub_request(:post, "#{base_url}/query")
        .to_return(status: 200, body: response_body)

      result = client.query_all(statement: "SELECT 1")
      expect(result[:metadata]).to eq({ "metadata" => "m" })
      expect(result[:columns]).to eq({ "columns" => ["c"] })
      expect(result[:rows]).to eq([{ "c" => 1 }])
    end
  end

  describe "error handling" do
    it "raises AuthError on 401" do
      stub_request(:post, "#{base_url}/append")
        .to_return(status: 401)
      
      expect {
        client.append(catalog: "a", schema: "b", table: "c", payload: {})
      }.to raise_error(Altertable::Lakehouse::AuthError)
    end

    it "raises BadRequestError on 400" do
      stub_request(:post, "#{base_url}/append")
        .to_return(status: 400, body: "Invalid data")
      
      expect {
        client.append(catalog: "a", schema: "b", table: "c", payload: {})
      }.to raise_error(Altertable::Lakehouse::BadRequestError, /Invalid data/)
    end
  end
  
  describe "#upload" do
    it "uploads file as octet-stream" do
      stub_request(:post, "#{base_url}/upload")
        .with(
          query: { "catalog" => "c", "schema" => "s", "table" => "t", "format" => "csv", "mode" => "append" },
          headers: { "Content-Type" => "application/octet-stream" },
          body: "file-content"
        )
        .to_return(status: 200, body: { ok: true }.to_json)

      client.upload(catalog: "c", schema: "s", table: "t", format: "csv", mode: "append", file_io: "file-content")
    end
  end
end
