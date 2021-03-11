# frozen_string_literal: true

module Abt
  class Cli
    class Prompt
      attr_reader :output

      def initialize(output:)
        @output = output
      end

      def text(question)
        output.print("#{question}: ")
        read_user_input
      end

      def boolean(text)
        output.puts text

        loop do
          output.print("(y / n): ")

          case read_user_input
          when "y", "Y" then return true
          when "n", "N" then return false
          else
            output.puts "Invalid choice"
          end
        end
      end

      def choice(text, options, nil_option: false)
        output.puts "#{text}:"

        if options.length.zero?
          raise Abort, "No available options" unless nil_option

          output.puts "No available options"
          return nil
        end

        print_options(options)
        select_options(options, nil_option)
      end

      def search(text, options)
        output.puts text

        loop do
          choice = get_search_result(options)
          break choice unless choice.nil?
        end
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
        str = "("
        str += options_length > 1 ? "1-#{options_length}" : "1"
        str += nil_option_string(nil_option)
        str += "): "
        output.print(str)

        input = read_user_input

        return nil if nil_option && input == nil_option_character(nil_option)

        option_number = input.to_i
        if option_number <= 0 || option_number > options_length
          output.puts "Invalid selection"
          return nil
        end

        option_number
      end

      def nil_option_string(nil_option)
        return "" unless nil_option

        ", #{nil_option_character(nil_option)}: #{nil_option_description(nil_option)}"
      end

      def nil_option_character(nil_option)
        return "q" if nil_option == true

        nil_option[0]
      end

      def nil_option_description(nil_option)
        return "back" if nil_option == true
        return nil_option if nil_option.is_a?(String)

        nil_option[1]
      end

      def read_user_input
        open(tty_path, &:gets).strip # rubocop:disable Security/Open
      end

      def get_search_result(options)
        matches = matches_for_string(text("Enter search"), options)
        if matches.empty?
          output.puts("No matches")
          return
        end

        output.puts("Showing the 10 first matches") if matches.size > 10
        choice("Select a match", matches[0...10], nil_option: true)
      end

      def matches_for_string(string, options)
        search_string = sanitize_string(string)

        options.select do |option|
          sanitize_string(option["name"]).include?(search_string)
        end
      end

      def sanitize_string(string)
        string.downcase.gsub(/[^\w]/, "")
      end

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
