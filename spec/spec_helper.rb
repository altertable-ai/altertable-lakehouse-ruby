require "bundler/setup"
require "altertable/lakehouse"
require "securerandom"
require_relative "support/altertable_container"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
