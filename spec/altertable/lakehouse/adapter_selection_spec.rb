require "spec_helper"

RSpec.describe Altertable::Lakehouse::Client do
  describe "#initialize adapter selection" do
    let(:base_options) { { username: "u", password: "p" } }

    context "when adapter is explicitly provided" do
      it "uses FaradayAdapter when :faraday is requested" do
        client = described_class.new(**base_options, adapter: :faraday)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Lakehouse::Adapters::FaradayAdapter)
      end

      it "uses HttpxAdapter when :httpx is requested" do
        client = described_class.new(**base_options, adapter: :httpx)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Lakehouse::Adapters::HttpxAdapter)
      end

      it "uses NetHttpAdapter when :net_http is requested" do
        client = described_class.new(**base_options, adapter: :net_http)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Lakehouse::Adapters::NetHttpAdapter)
      end
    end

    context "when adapter is auto-detected" do
      # These tests are tricky because we can't easily unload constants/gems in the same process.
      # We assume Faraday is loaded because of spec_helper or previous requires.
      
      it "defaults to Faraday if Faraday is defined" do
        expect(defined?(Faraday)).to be_truthy
        client = described_class.new(**base_options)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Lakehouse::Adapters::FaradayAdapter)
      end
      
      # We can't easily test the fallback to Net::HTTP unless we run in a process without Faraday.
    end
  end

  describe "#initialize timeout configuration" do
    let(:base_options) { { username: "u", password: "p", base_url: "http://example.com" } }

    it "defaults open_timeout to 5 seconds" do
      client = described_class.new(**base_options, adapter: :net_http)
      adapter = client.instance_variable_get(:@adapter)

      expect(client.instance_variable_get(:@open_timeout)).to eq(5)
      expect(adapter.instance_variable_get(:@open_timeout)).to eq(5)
    end

    it "passes custom open_timeout to adapters" do
      client = described_class.new(**base_options, adapter: :net_http, open_timeout: 2)
      adapter = client.instance_variable_get(:@adapter)

      expect(client.instance_variable_get(:@open_timeout)).to eq(2)
      expect(adapter.instance_variable_get(:@open_timeout)).to eq(2)
    end

    it "configures Faraday open_timeout separately from request timeout" do
      client = described_class.new(**base_options, adapter: :faraday, timeout: 10, open_timeout: 2)
      adapter = client.instance_variable_get(:@adapter)
      conn = adapter.instance_variable_get(:@conn)

      expect(conn.options.timeout).to eq(10)
      expect(conn.options.open_timeout).to eq(2)
    end

    it "configures HTTPX connect_timeout separately from operation_timeout" do
      client = described_class.new(**base_options, adapter: :httpx, timeout: 10, open_timeout: 2)
      adapter = client.instance_variable_get(:@adapter)
      httpx_client = adapter.instance_variable_get(:@client)
      timeout_options = httpx_client.instance_variable_get(:@options).timeout

      expect(timeout_options[:operation_timeout]).to eq(10)
      expect(timeout_options[:connect_timeout]).to eq(2)
    end

    it "configures Net::HTTP open_timeout separately from read_timeout" do
      adapter = Altertable::Lakehouse::Adapters::NetHttpAdapter.new(
        base_url: "http://example.com",
        timeout: 10,
        open_timeout: 2,
        headers: {}
      )
      http = instance_double(Net::HTTP)
      response = instance_double(Net::HTTPResponse, code: "200", body: "{}", to_hash: {})

      allow(http).to receive(:request).and_return(response)
      expect(Net::HTTP).to receive(:start)
        .with("example.com", 80, use_ssl: false, open_timeout: 2, read_timeout: 10)
        .and_yield(http)

      adapter.get("/")
    end
  end
end
