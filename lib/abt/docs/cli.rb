# frozen_string_literal: true

module Abt
  module Docs
    module Cli
      class << self
        def content
          <<~TXT
            abt <command> [<provider-URI>][ <flags> --]] [<provider-URI>...]

            #{example_commands}

            Available commands:
            #{providers_commands}
          TXT
        end

        private

        def example_commands
          lines = []

          Docs.examples.each_with_index do |(title, examples), index|
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

          Docs.providers.each_with_index do |(provider_name, commands_definition), index|
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
