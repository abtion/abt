# frozen_string_literal: true

module Abt
  class Cli
    module Dialogs
      def prompt(question)
        err_output.print "#{question}: "
        read_user_input.strip
      end

      def prompt_choice(text, options, allow_back_option = false)
        if options.one?
          warn "Selected: #{options.first['name']}"
          return options.first
        end

        warn "#{text}:"

        print_options(options)
        select_options(options, allow_back_option)
      end

      private

      def print_options(options)
        options.each_with_index do |option, index|
          warn "(#{index + 1}) #{option['name']}"
        end
      end

      def select_options(options, allow_back_option)
        while (number = read_option_number(options.length, allow_back_option))
          if number.nil?
            return nil if allow_back_option

            abort
          end

          option = options[number - 1]

          warn "Selected: (#{number}) #{option['name']}"
          return option
        end
      end

      def read_option_number(options_length, allow_back_option)
        err_output.print "(1-#{options_length}#{allow_back_option ? ', q: back' : ''}): "

        input = read_user_input

        return nil if allow_back_option && input == 'q'

        option_number = input.to_i
        if option_number <= 0 || option_number > options_length
          warn 'Invalid selection'
          return nil
        end

        option_number
      end

      def read_user_input
        open('/dev/tty', &:gets).strip
      end
    end
  end
end
