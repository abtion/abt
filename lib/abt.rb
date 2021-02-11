# frozen_string_literal: true

require 'dry-inflector'
require 'faraday'
require 'oj'
require 'open3'
require 'stringio'
require 'optparse'

Dir.glob("#{File.dirname(File.absolute_path(__FILE__))}/abt/*.rb").sort.each do |file|
  require file
end

module Abt
  module Providers; end

  def self.schemes
    Providers.constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
  end

  def self.scheme_provider(scheme)
    const_name = Helpers.command_to_const(scheme)
    Providers.const_get(const_name) if Providers.const_defined?(const_name)
  end
end
