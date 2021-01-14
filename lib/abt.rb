# frozen_string_literal: true

Dir.glob("#{File.dirname(File.absolute_path(__FILE__))}/abt/*.rb").sort.each do |file|
  require file
end

module Abt
  def self.provider_names
    Providers.constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
  end

  def self.provider_module(name)
    const_name = Helpers.command_to_const(name)
    Providers.const_get(const_name) if Providers.const_defined?(const_name)
  end
end
