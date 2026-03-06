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
end
