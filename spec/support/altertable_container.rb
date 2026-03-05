require "testcontainers"

# In CI the mock is provided as a GitHub Actions service container already
# bound to localhost:15000, so we skip spinning one up ourselves.
unless ENV["CI"]
  container = Testcontainers::DockerContainer
    .new("ghcr.io/altertable-ai/altertable-mock:latest")
    .with_exposed_port(15000)
    .with_env("ALTERTABLE_MOCK_USERS", "testuser:testpass")
    .with_wait_for(:http, path: "/", container_port: 15000, timeout: 30)

  container.start

  # Expose the mapped port so the specs can read it at runtime.
  mapped_port = container.mapped_port(15000)
  ENV["ALTERTABLE_MOCK_PORT"] = mapped_port.to_s

  # Tear down after the full suite finishes.
  at_exit { container.stop }
end
