require "json"

module Altertable
  module SpecSupport
    # docker-api only honors DOCKER_HOST / DOCKER_URL, then unix:///var/run/docker.sock.
    # Docker Desktop on macOS keeps the live socket on the current context instead.
    module DockerHost
      DEFAULT_SOCKET = "/var/run/docker.sock"

      module_function

      def resolve(env: ENV, home: Dir.home, sockets: ->(path) { File.socket?(path) })
        return nil if env["DOCKER_HOST"].to_s != "" || env["DOCKER_URL"].to_s != ""
        return nil if sockets.call(DEFAULT_SOCKET)

        from_context(home, sockets) || from_known_sockets(home, sockets)
      end

      def from_context(home, sockets)
        config_path = File.join(home, ".docker", "config.json")
        return nil unless File.file?(config_path)

        config = JSON.parse(File.read(config_path))
        return nil unless config.is_a?(Hash)

        name = config["currentContext"]
        return nil if name.nil? || name.to_s.empty?

        Dir.glob(File.join(home, ".docker", "contexts", "meta", "*", "meta.json")).each do |meta_path|
          meta = JSON.parse(File.read(meta_path))
          next unless meta.is_a?(Hash) && meta["Name"] == name

          host = meta.dig("Endpoints", "docker", "Host")
          return host if usable?(host, sockets)
        end

        nil
      rescue JSON::ParserError, Errno::ENOENT, Errno::EACCES
        nil
      end

      def from_known_sockets(home, sockets)
        [
          File.join(home, ".docker", "run", "docker.sock"),
          File.join(home, ".colima", "default", "docker.sock"),
          File.join(home, ".rd", "docker.sock")
        ].each do |path|
          return "unix://#{path}" if sockets.call(path)
        end

        nil
      end

      def usable?(host, sockets)
        return false unless host.is_a?(String) && !host.empty?
        return sockets.call(host.delete_prefix("unix://")) if host.start_with?("unix://")

        host.include?("://")
      end
      private_class_method :from_context, :from_known_sockets, :usable?
    end
  end
end
