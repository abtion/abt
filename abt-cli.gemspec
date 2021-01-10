# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'abt-cli'
  s.summary = ['Very versatile scripts']
  s.authors = ['Jesper Sørensen']
  s.version = '0.0.1'
  s.executables = ['abt']

  s.add_dependency 'dry-inflector'
  s.add_dependency 'faraday'
  s.add_dependency 'oj'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rubocop'
end
