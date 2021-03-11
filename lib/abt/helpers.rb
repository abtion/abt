# frozen_string_literal: true

module Abt
  module Helpers
    class << self
      def const_to_command(string)
        string = string.to_s.dup
        string[0] = string[0].downcase
        string.gsub(/([A-Z])/, '-\1').downcase
      end

      def command_to_const(string)
        inflector = Dry::Inflector.new
        inflector.camelize(inflector.underscore(string))
      end

      def read_user_input
        open(tty_path, &:gets).strip # rubocop:disable Security/Open
      end

      private

      def tty_path
        @tty_path ||= begin
          candidates = ["/dev/tty", "CON:"] # Unix: '/dev/tty', Windows: 'CON:'
          selected = candidates.find { |candidate| File.exist?(candidate) }
          raise Abort, "Unable to prompt for user input" if selected.nil?

          selected
        end
      end
    end
  end
end
