# frozen_string_literal: true

module Abt
  class Cli
    module Dialogs
      def prompt(question)
        STDERR.print "#{question}: "
        read_user_input.strip
      end

      def prompt_choice(text, options, allow_back_option = false)
        if options.one?
          warn "Selected: #{options.first['name']}"
          return options.first
        end

        warn "#{text}:"

        options.each_with_index do |option, index|
          warn "(#{index + 1}) #{option['name']}"
        end

        loop do
          STDERR.print "(1-#{options.length}#{allow_back_option ? ', q: back' : ''}): "

          input = read_user_input.strip

          return nil if allow_back_option && input == 'q'

          option_number = input.to_i
          abort 'Invalid selection' if option_number <= 0 || option_number > options.length

          option = options[option_number - 1]

          warn "Selected: (#{option_number}) #{option['name']}"
          return option
        end
      end

      private

      def read_user_input
        open('/dev/tty', &:gets)
      end
    end
  end
end
