# frozen_string_literal: true

module Abt
  class Cli
    class Prompt
      attr_reader :output

      def initialize(output:)
        @output = output
      end

      def text(question)
        output.print "#{question}: "
        read_user_input
      end

      def boolean(text)
        output.puts text

        loop do
          output.print '(y / n): '

          case read_user_input
          when 'y', 'Y' then return true
          when 'n', 'N' then return false
          else
            output.puts 'Invalid choice'
            next
          end
        end
      end

      def choice(text, options, nil_option = false)
        output.puts "#{text}:"

        if options.length.zero?
          raise AbortError, 'No available options' unless nil_option

          output.puts 'No available options'
          return nil
        end

        print_options(options)
        select_options(options, nil_option)
      end

      private

      def print_options(options)
        options.each_with_index do |option, index|
          output.puts "(#{index + 1}) #{option['name']}"
        end
      end

      def select_options(options, nil_option)
        loop do
          number = read_option_number(options.length, nil_option)
          if number.nil?
            return nil if nil_option

            next
          end

          option = options[number - 1]

          output.puts "Selected: (#{number}) #{option['name']}"
          return option
        end
      end

      def read_option_number(options_length, nil_option)
        output.print '('
        output.print options_length > 1 ? "1-#{options_length}" : '1'
        output.print nil_option_string(nil_option)
        output.print '): '

        input = read_user_input

        return nil if nil_option && input == nil_option_character(nil_option)

        option_number = input.to_i
        if option_number <= 0 || option_number > options_length
          output.puts 'Invalid selection'
          return nil
        end

        option_number
      end

      def nil_option_string(nil_option)
        return '' unless nil_option

        ", #{nil_option_character(nil_option)}: #{nil_option_description(nil_option)}"
      end

      def nil_option_character(nil_option)
        return 'q' if nil_option == true

        nil_option[0]
      end

      def nil_option_description(nil_option)
        return 'back' if nil_option == true
        return nil_option if nil_option.is_a?(String)

        nil_option[1]
      end

      def read_user_input
        open('/dev/tty', &:gets).strip
      end
    end
  end
end
