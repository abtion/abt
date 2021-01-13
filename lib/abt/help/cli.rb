# frozen_string_literal: true

module Abt
  module Help
    module Cli
      class << self
        def content
          <<~TXT
            Usage: abt <command> [<provider:arguments>...]

            #{example_commands}

            Available commands:
            #{providers_commands}
          TXT
        end

        private

        def example_commands
          lines = []

          Help.examples.each_with_index do |(title, examples), index|
            lines << '' unless index.zero?
            lines << title

            max_length = examples.keys.map(&:length).max
            examples.each do |(command, description)|
              lines << "   #{command.ljust(max_length)}   #{description}"
            end
          end

          lines.join("\n")
        end

        def providers_commands
          lines = []

          Help.providers.each_with_index do |(provider_name, commands_definition), index|
            lines << '' unless index.zero?
            lines << "#{inflector.humanize(provider_name)}:"

            max_length = commands_definition.keys.map(&:length).max

            commands_definition.each do |(command, description)|
              lines << "   #{command.ljust(max_length)}   #{description}"
            end
          end

          lines.join("\n")
        end

        def inflector
          Dry::Inflector.new
        end
      end
    end
  end
end
