require "json"
require "tmpdir"
require_relative "docker_host"

RSpec.describe Altertable::SpecSupport::DockerHost do
  def write_context(home, name:, host:)
    meta_dir = File.join(home, ".docker", "contexts", "meta", "abc")
    FileUtils.mkdir_p(meta_dir)
    File.write(File.join(home, ".docker", "config.json"), JSON.generate("currentContext" => name))
    File.write(
      File.join(meta_dir, "meta.json"),
      JSON.generate("Name" => name, "Endpoints" => {"docker" => {"Host" => host}})
    )
  end

  it "keeps an explicit DOCKER_HOST" do
    env = {"DOCKER_HOST" => "unix:///custom.sock"}

    expect(described_class.resolve(env: env, home: "/missing", sockets: ->(_) { true })).to be_nil
  end

  it "keeps the default socket when it exists" do
    expect(described_class.resolve(env: {}, home: "/missing", sockets: ->(path) { path == "/var/run/docker.sock" })).to be_nil
  end

  it "uses the current Docker context socket when the default socket is missing" do
    Dir.mktmpdir do |home|
      socket = File.join(home, ".docker", "run", "docker.sock")
      write_context(home, name: "desktop-linux", host: "unix://#{socket}")

      resolved = described_class.resolve(env: {}, home: home, sockets: ->(path) { path == socket })

      expect(resolved).to eq("unix://#{socket}")
    end
  end

  it "falls back to the Docker Desktop socket when context metadata is absent" do
    Dir.mktmpdir do |home|
      socket = File.join(home, ".docker", "run", "docker.sock")

      resolved = described_class.resolve(env: {}, home: home, sockets: ->(path) { path == socket })

      expect(resolved).to eq("unix://#{socket}")
    end
  end

  it "returns nil when no socket can be found" do
    Dir.mktmpdir do |home|
      expect(described_class.resolve(env: {}, home: home, sockets: ->(_) { false })).to be_nil
    end
  end
end
