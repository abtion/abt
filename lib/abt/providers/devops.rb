# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/devops/*.rb").sort.each { |file| require file }
Dir.glob("#{File.expand_path(__dir__)}/devops/commands/*.rb").sort.each { |file| require file }

module Abt
  module Providers
    module Devops
      def self.command_names
        Commands.constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
      end

      def self.command_class(name)
        const_name = Helpers.command_to_const(name)
        Commands.const_get(const_name) if Commands.const_defined?(const_name)
      end
    end
  end
end
