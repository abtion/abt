# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/global_commands/*.rb").sort.each { |file| require file }

module Abt
  class Cli
    module GlobalCommands
      def self.command_names
        constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
      end

      def self.command_class(name)
        name = "help" if [nil, "-h", "--help"].include?(name)
        name = "version" if ["-v", "--version"].include?(name)

        const_name = Helpers.command_to_const(name)
        return unless const_defined?(const_name)

        const_get(const_name)
      end
    end
  end
end
