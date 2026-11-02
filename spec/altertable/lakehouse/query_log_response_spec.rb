# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Lakehouse::Models::QueryLogResponse do
  let(:base) do
    {
      "uuid" => "03dc0291-ca25-439b-ab3c-4d76b6cd0892",
      "duration_ms" => nil,
      "start_time" => "2026-10-21T12:47:00.38332771Z",
      "end_time" => nil,
      "query" => "SELECT count(DISTINCT \"WatchID\") AS w FROM clickbench.main.hits",
      "client_interface" => "HTTP",
      "error" => nil,
      "visible" => true,
      "stats" => nil,
      "requested_by" => "someone",
      "user_agent" => "ua",
      "session_id" => "01a15e80-2126-72b1-9293-3ad1199ea0b2",
      "threads" => 32,
      "fingerprint" => nil,
      "session_catalog" => nil,
      "session_schema" => nil
    }
  end

  it "wraps top-level progress fields of a running query in a QueryProgress" do
    log = described_class.from_h(
      base.merge("percentage" => 30.001622776575903, "rows_processed" => 30_000_872, "total_rows" => 99_997_499)
    )

    expect(log.progress).to eq(
      Altertable::Lakehouse::Models::QueryProgress.new(
        percentage: 30.001622776575903, rows_processed: 30_000_872, total_rows: 99_997_499
      )
    )
    expect(log.threads).to eq(32)
    expect(log.client_interface).to eq("HTTP")
  end

  it "coerces an integral percentage to a Float" do
    log = described_class.from_h(base.merge("percentage" => 0, "rows_processed" => 0, "total_rows" => 10))

    expect(log.progress.percentage).to eql(0.0)
  end

  it "leaves progress nil when the response omits it" do
    log = described_class.from_h(base.merge("end_time" => "2026-10-21T12:47:03Z", "duration_ms" => 2_617))

    expect(log.progress).to be_nil
    expect(log.duration_ms).to eq(2_617)
  end
end
