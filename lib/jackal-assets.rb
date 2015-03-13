require 'miasma'
require 'miasma-local'
require 'bogo'

module Jackal
  # Asset storage helper
  module Assets
    autoload :Store, 'jackal-assets/store'
    autoload :Error, 'jackal-assets/errors'
  end
end

require 'jackal-assets/version'
