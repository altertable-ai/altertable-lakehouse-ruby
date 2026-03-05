lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "altertable/lakehouse/version"

Gem::Specification.new do |spec|
  spec.name = "altertable-lakehouse"
  spec.version = Altertable::Lakehouse::VERSION
  spec.authors = ["Altertable AI"]
  spec.email = ["support@altertable.ai"]

  spec.summary = "Official Ruby client for Altertable Lakehouse"
  spec.description = "Official Ruby client for Altertable Lakehouse API."
  spec.homepage = "https://github.com/altertable-ai/altertable-lakehouse-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/altertable-ai/altertable-lakehouse-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/altertable-ai/altertable-lakehouse-ruby/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.12"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "faraday-net_http" # Explicit adapter dependency
  spec.add_dependency "base64"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "testcontainers"
end
