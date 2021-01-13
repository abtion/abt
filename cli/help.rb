# frozen_string_literal: true

require 'stringio'

module Abt
  class Cli
    module Help
      def help_text
        text = StringIO.new

        text.puts <<~TXT
          Usage: abt <command> [<provider:arguments>...]

          Multiple providers and arguments can be passed, e.g.:
            `abt init asana harvest`
            `abt pick-task asana harvest`
            `abt start asana harvest`
            `abt clear asana harvest`

          Command output can be piped, e.g.:
            `abt tasks asana | grep -i <name of task>`
            `abt tasks asana | grep -i <name of task> | abt start`

          Available commands:
        TXT

        Abt::Providers.constants.sort.each_with_index do |provider_name, index|
          text.puts '' unless index.zero?
          text.puts commandize(provider_name)

          provider_class = Abt::Providers.const_get(provider_name)
          command_texts = []
          provider_class.constants.sort.each do |command_name|
            command_class = provider_class.const_get(command_name)

            if command_class.respond_to? :command
              command_texts.push([command_class.command, command_class.description])
            end
          end

          max_length = command_texts.map(&:first).map(&:length).max
          command_texts.each do |(command, description)|
            text.puts("  #{command.ljust(max_length)} # #{description}")
          end
        end

        text.string.strip!
      end

      def help_md
        text = StringIO.new

        text.puts <<~MD
          # Abt
          This readme was generated with `abt help-md > README.md`

          ## Usage
          `abt <command> [<provider:arguments>...]`

          Multiple providers and arguments can be passed, e.g.:
          - `abt init asana harvest`
          - `abt pick-task asana harvest`
          - `abt start asana harvest`
          - `abt clear asana harvest`

          Command output can be piped, e.g.:
          - `abt tasks asana | grep -i <name of task>`
          - `abt tasks asana | grep -i <name of task> | abt start`

          ## Available commands:
        MD

        Abt::Providers.constants.sort.each_with_index do |provider_name, index|
          text.puts '' unless index.zero?
          text.puts "### #{provider_name}"
          text.puts '| Command | Description |'
          text.puts '| :------ | :---------- |'

          provider_class = Abt::Providers.const_get(provider_name)
          command_texts = []
          provider_class.constants.sort.each do |command_name|
            command_class = provider_class.const_get(command_name)

            if command_class.respond_to? :command
              command_texts.push([command_class.command, command_class.description])
            end
          end

          max_length = command_texts.map(&:first).map(&:length).max
          command_texts.each do |(command, description)|
            text.puts("| `#{command.ljust(max_length)}` | #{description} |")
          end
        end

        text.string.strip!
      end

      def commandize(string)
        string = string.to_s
        string[0] = string[0].downcase
        string.gsub(/([A-Z])/, '-\1').downcase
      end
    end
  end
end
