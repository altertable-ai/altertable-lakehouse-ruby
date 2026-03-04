require_relative "lakehouse/version"
require_relative "lakehouse/client"
require_relative "lakehouse/models"
require_relative "lakehouse/errors"

module Altertable
  module Lakehouse
    class Error < StandardError; end
  end
end
