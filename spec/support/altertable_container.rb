require "testcontainers"
require_relative "docker_host"

# In CI the mock is provided as a GitHub Actions service container already
# bound to localhost:15000, so we skip spinning one up ourselves.
unless ENV["CI"]
  docker_host = Altertable::SpecSupport::DockerHost.resolve
  ENV["DOCKER_HOST"] = docker_host if docker_host

  container = Testcontainers::DockerContainer
    .new("ghcr.io/altertable-ai/altertable-mock:latest")
    .with_exposed_port(15000)
    .with_env("ALTERTABLE_MOCK_USERS", "testuser:testpass")
    # The mock answers 404 on /, so waiting for HTTP 200 never succeeds.
    .with_wait_for(:tcp_port, 15000, timeout: 30)

  at_exit { container.stop if container.running? }

  container.start

  # Expose the mapped port so the specs can read it at runtime.
  mapped_port = container.mapped_port(15000)
  ENV["ALTERTABLE_MOCK_PORT"] = mapped_port.to_s
end
