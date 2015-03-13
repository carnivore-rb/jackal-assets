$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jackal-assets/version'
Gem::Specification.new do |s|
  s.name = 'jackal-assets'
  s.version = Jackal::Assets::VERSION.version
  s.summary = 'Jackal Asset Interface'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'http://github.com/carnivore-rb/jackal-assets'
  s.description = 'Jackal Assets'
  s.license = 'Apache 2.0'
  s.require_path = 'lib'
  s.add_runtime_dependency 'jackal'
  s.add_runtime_dependency 'miasma'
  s.add_runtime_dependency 'miasma-local'
  s.add_runtime_dependency 'rubyzip'
  s.add_runtime_dependency 'bogo', '> 0.1.14'
  s.files = Dir['{lib}/**/**/*'] + %w(jackal-assets.gemspec README.md CHANGELOG.md)
end
