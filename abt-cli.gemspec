# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'abt/version'

Gem::Specification.new do |spec|
  spec.name = 'abt-cli'
  spec.summary = ['Versatile scripts']
  spec.authors = ['Jesper Sørensen']
  spec.version = Abt::VERSION
  spec.executables = ['abt']
  spec.require_paths = ['lib']

  spec.metadata['source_code_uri'] = 'https://github.com/abtion/abt'

  spec.files = Dir.glob("#{__dir__}/{bin,lib}/**/*.rb").sort.map do |file|
    file
  end

  spec.add_dependency 'dry-inflector', '~> 0.2'
  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'oj', '~> 3.10'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rubocop'
end
