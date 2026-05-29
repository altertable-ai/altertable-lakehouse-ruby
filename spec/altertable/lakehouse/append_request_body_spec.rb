# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Lakehouse::Client do
  describe "#append batch payload encoding" do
    let(:adapter) { instance_double(Altertable::Lakehouse::Adapters::NetHttpAdapter) }
    let(:client) do
      described_class.new(
        username: "user",
        password: "pass",
        base_url: "http://example.com",
        adapter: :net_http
      )
    end

    before do
      client.instance_variable_set(:@adapter, adapter)
      allow(adapter).to receive(:post).and_return(
        Altertable::Lakehouse::Adapters::Response.new(200, { ok: true }.to_json, {})
      )
    end

    it "JSON-encodes an array of row hashes for batch append" do
      client.append(
        catalog: "altertable",
        schema: "main",
        table: "usage",
        payload: [
          { timestamp: "2026-05-27T09:00:00Z", metrics_type: "storage", variant: "hetzner", value: 3 },
          { timestamp: "2026-05-27T10:00:00Z", metrics_type: "storage", variant: "hetzner", value: 1 }
        ]
      )

      expect(adapter).to have_received(:post).with(
        "/append",
        hash_including(
          body: [
            { timestamp: "2026-05-27T09:00:00Z", metrics_type: "storage", variant: "hetzner", value: 3 },
            { timestamp: "2026-05-27T10:00:00Z", metrics_type: "storage", variant: "hetzner", value: 1 }
          ].to_json
        )
      )
    end
  end
end
