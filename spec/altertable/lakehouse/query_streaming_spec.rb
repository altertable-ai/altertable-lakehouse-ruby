require "spec_helper"
require "socket"

# Runs #query against a local HTTP/1.1 server that sends a chunked NDJSON
# body piece by piece, pausing until the test lets it continue. A row the
# client yields during a pause proves it did not wait for the whole body.
RSpec.describe Altertable::Lakehouse::Client, "#query streaming" do
  # Each step is a body chunk to send, or :wait to block until the test
  # pushes to `release`.
  class StreamingServer
    attr_reader :port, :release

    def initialize(status:, steps:)
      @status = status
      @steps = steps
      @release = Queue.new
      @server = TCPServer.new("127.0.0.1", 0)
      @port = @server.addr[1]
      @thread = Thread.new { serve }
    end

    def stop
      @release << :stop
      @server.close
      @thread.kill
    end

    private

    def serve
      socket = @server.accept
      read_request(socket)
      socket.write("HTTP/1.1 #{@status} Whatever\r\nContent-Type: application/x-ndjson\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n")
      @steps.each do |step|
        if step == :wait
          @release.pop
        else
          socket.write("#{step.bytesize.to_s(16)}\r\n#{step}\r\n")
          socket.flush
        end
      end
      socket.write("0\r\n\r\n")
      socket.close
    rescue IOError, Errno::EPIPE, Errno::ECONNRESET
      nil
    end

    def read_request(socket)
      content_length = 0
      while (line = socket.gets) && line != "\r\n"
        content_length = line.split(":", 2).last.to_i if line.downcase.start_with?("content-length:")
      end
      socket.read(content_length)
    end
  end

  def client_for(server, adapter)
    described_class.new(
      username: "u",
      password: "p",
      base_url: "http://127.0.0.1:#{server.port}",
      adapter: adapter,
      timeout: 5,
      proxy: nil
    )
  end

  after { @server&.stop }

  %i[faraday httpx net_http].each do |adapter|
    context "with the #{adapter} adapter" do
      it "yields rows before the response ends, joining a line split across chunks" do
        @server = StreamingServer.new(
          status: 200,
          steps: [
            "{\"statement\":\"SELECT id, name\"}\n[{\"name\":\"id\",\"type\":\"INTEGER\"},",
            "{\"name\":\"name\",\"type\":\"VARCHAR\"}]\n[1,\"Zoë\"]\n[2,\"b",
            "ob\"]\n",
            :wait,
            "[3,\"carol\"]"
          ]
        )
        result = client_for(@server, adapter).query(statement: "SELECT id, name")

        rows = []
        result.each do |row|
          rows << row
          # The server only sends row 3 once it is released, so rows 1 and 2
          # must arrive while the response is still open.
          @server.release << :go if rows.length == 2
        end

        expect(rows).to eq([
          { "id" => 1, "name" => "Zoë" },
          { "id" => 2, "name" => "bob" },
          { "id" => 3, "name" => "carol" }
        ])
        expect(result.metadata).to eq("statement" => "SELECT id, name")
        expect(result.columns.map(&:name)).to eq(%w[id name])
      end

      it "raises QueryError on an in-stream error line after yielding earlier rows" do
        @server = StreamingServer.new(
          status: 200,
          steps: [
            "{\"statement\":\"SELECT id\"}\n[{\"name\":\"id\",\"type\":\"INTEGER\"}]\n[1]\n",
            "{\"error\":\"out of memory\"}\n"
          ]
        )
        rows = []

        expect {
          client_for(@server, adapter).query(statement: "SELECT id").each { |row| rows << row }
        }.to raise_error(Altertable::Lakehouse::QueryError, "out of memory") { |error|
          expect(error.line_index).to eq(3)
        }
        expect(rows).to eq([{ "id" => 1 }])
      end

      it "raises BadRequestError with the body on a 400" do
        @server = StreamingServer.new(status: 400, steps: ["invalid ", "SQL\n"])

        expect {
          client_for(@server, adapter).query(statement: "SELECT * FROM").to_a
        }.to raise_error(Altertable::Lakehouse::BadRequestError, "Bad Request: invalid SQL")
      end

      it "raises AuthError on a 401" do
        @server = StreamingServer.new(status: 401, steps: ["nope"])

        expect {
          client_for(@server, adapter).query(statement: "SELECT 1").to_a
        }.to raise_error(Altertable::Lakehouse::AuthError)
      end

      it "raises ApiError with the status and body on other errors" do
        @server = StreamingServer.new(status: 503, steps: ["overloaded"])

        expect {
          client_for(@server, adapter).query(statement: "SELECT 1").to_a
        }.to raise_error(Altertable::Lakehouse::ApiError, "API Error 503: overloaded")
      end

      it "returns the same shape from query_all" do
        @server = StreamingServer.new(
          status: 200,
          steps: ["{\"statement\":\"SELECT 1 AS n\"}\n[{\"name\":\"n\",\"type\":\"INTEGER\"}]\n", "[1]\n"]
        )

        expect(client_for(@server, adapter).query_all(statement: "SELECT 1 AS n")).to eq(
          metadata: { "statement" => "SELECT 1 AS n" },
          columns: [Altertable::Lakehouse::ColumnDescriptor.new(name: "n", type: "INTEGER")],
          rows: [{ "n" => 1 }]
        )
      end
    end
  end

  describe Altertable::Lakehouse::NdjsonStream do
    it "holds the body back until it sees a 2xx status, then parses it on finish" do
      values = []
      stream = described_class.new { |value| values << value }

      stream.write("{\"a\":1}\n{\"b\"", nil)
      stream.write(":2}", nil)
      expect(values).to be_empty

      stream.finish
      expect(values).to eq([{ "a" => 1 }, { "b" => 2 }])
    end

    it "keeps a multibyte character split across chunks intact" do
      values = []
      stream = described_class.new { |value| values << value }
      bytes = "[\"Zoë\"]\n".b

      stream.write(bytes.byteslice(0, 5), 200)
      stream.write(bytes.byteslice(5..), 200)

      expect(values).to eq([["Zoë"]])
    end

    it "raises ParseError on a malformed line" do
      stream = described_class.new { |_value| nil }

      expect { stream.write("{not json}\n", 200) }.to raise_error(Altertable::Lakehouse::ParseError, /Malformed \/query line/)
    end
  end
end
