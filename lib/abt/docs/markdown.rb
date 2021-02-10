# frozen_string_literal: true

module Abt
  module Docs
    module Markdown
      class << self
        def readme
          <<~MD
            # Abt
            This readme was generated with `abt readme > README.md`

            ## Usage
            `abt <command> [<provider-URI>] [<flags> --] [<provider-URI>] ...`

            #{example_commands}

            ## Available commands:
            Some commands have `[options]`. Run such a command with `--help` flag to view supported flags, e.g: `abt track harvest -h`

            #{provider_commands}
          MD
        end

        private

        def example_commands
          lines = []

          examples = Docs.basic_examples.merge(Docs.extended_examples)
          examples.each_with_index do |(title, commands), index|
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

            max_length = commands.values.map(&:first).map(&:length).max

            commands.each do |(_command, (usage, description))|
              adjusted_usage = "`#{usage}`".ljust(max_length + 2)
              lines << "| #{adjusted_usage} | #{description} |"
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
