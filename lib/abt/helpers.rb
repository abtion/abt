# frozen_string_literal: true

module Abt
  module Helpers
    def self.const_to_command(string)
      string = string.to_s
      string[0] = string[0].downcase
      string.gsub(/([A-Z])/, '-\1').downcase
    end

    def self.command_to_const(string)
      inflector = Dry::Inflector.new
      inflector.camelize(inflector.underscore(string))
    end
  end
end
