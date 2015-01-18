require 'jackal-assets'

module Jackal
  module Assets
    # General error
    class Error < StandardError
      # Object not found
      class NotFound < Error
      end
    end
  end
end
