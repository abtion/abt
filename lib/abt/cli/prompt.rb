# frozen_string_literal: true

module Abt
  class Cli
    class Prompt
      attr_reader :output

      def initialize(output:)
        @output = output
      end

      def text(question)
        output.print("#{question.strip}: ")
        Abt::Helpers.read_user_input
      end

      def boolean(text, default: nil)
        choices = [default == true ? "Y" : "y",
                   default == false ? "N" : "n"].join("/")

        output.print("#{text} (#{choices}): ")

        input = Abt::Helpers.read_user_input.downcase

        return true if input == "y"
        return false if input == "n"
        return default if input.empty? && !default.nil?

        output.puts "Invalid choice"
        boolean(text, default: default)
      end

      def choice(text, options, nil_option: false)
        output.puts "#{text.strip}:"

        if options.length.zero?
          raise Abort, "No available options" unless nil_option

          output.puts "No available options"
          return nil
        end

        print_options(options)
        select_option(options, nil_option)
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

      def select_option(options, nil_option)
        number = prompt_valid_option_number(options, nil_option)

        return nil if number.nil?

        option = options[number - 1]
        output.puts "Selected: (#{number}) #{option['name']}"
        option
      end

      def prompt_valid_option_number(options, nil_option)
        output.print(options_info(options, nil_option))
        input = Abt::Helpers.read_user_input

        return nil if nil_option && input == nil_option_character(nil_option)

        option_number = input.to_i
        return option_number if (1..options.length).cover?(option_number)

        output.puts "Invalid selection"

        # Prompt again if the selection was invalid
        prompt_valid_option_number(options, nil_option)
      end

      def options_info(options, nil_option)
        str = "("
        str += options.length > 1 ? "1-#{options.length}" : "1"
        str += nil_option_string(nil_option)
        str += "): "
        str
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
    end
  end
end
