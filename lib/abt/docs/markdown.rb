# frozen_string_literal: true

module Abt
  module Docs
    module Markdown
      class << self
        def content
          <<~MD
            # Abt
            This readme was generated with `abt help-md > README.md`

            ## Usage
            `abt <command> [<provider:arguments>...]`

            #{example_commands}

            ## Available commands:
            #{provider_commands}
          MD
        end

        private

        def example_commands
          lines = []

          Docs.examples.each_with_index do |(title, commands), index|
            lines << '' unless index.zero?
            lines << title

            commands.each do |(command, description)|
              formatted_description = description.nil? ? '' : ": #{description}"
              lines << "- `#{command}`#{formatted_description}"
            end
          end

          lines.join("\n")
        end

        def provider_commands # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          lines = []

          Docs.providers.each_with_index do |(provider_name, commands), index|
            lines << '' unless index.zero?
            lines << "### #{inflector.humanize(provider_name)}"
            lines << '| Command | Description |'
            lines << '| :------ | :---------- |'

            max_length = commands.keys.map(&:length).max

            commands.each do |(command, description)|
              adjusted_command = "`#{command}`".ljust(max_length + 2)
              lines << "| #{adjusted_command} | #{description} |"
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
