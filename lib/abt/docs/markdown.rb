# frozen_string_literal: true

module Abt
  module Docs
    module Markdown
      class << self
        def readme
          <<~MD
            # Abt

            Abt makes re-occuring tasks easily accessible from the terminal:
            - Moving asana tasks around
            - Tracking work/meetings in harvest
            - Consistently naming branches

            ## How does abt work?

            Abt is a hybrid of having small scripts each doing one thing:
            - `start-asana --project-gid xxxx --task-gid yyyy`
            - `start-harvest --project-id aaaa --task-id bbbb`

            And having a single highly advanced script that does everything with a single command:
            - `start xxxx/yyyy aaaa/bbbb`

            Abt looks like one command, but works like a bunch of light scripts:
            - `abt start asana:xxxx/yyyy harvest:aaaa/bbbb`

            ## Usage
            `abt <command> [<ARI>] [<options> --] [<ARI>] ...`

            Definitions:
            - `<command>`: Name of command to execute, e.g. `start`, `finalize` etc.
            - `<ARI>`: A URI-like resource identifier with a scheme and an optional path in the format: `<scheme>[:<path>]`. E.g., `harvest:11111111/22222222`
            - `<options>`: Optional flags for the command and ARI

            #{example_commands}

            ## Commands:

            Some commands have `[options]`. Run such a command with `--help` flag to view supported flags, e.g: `abt track harvest -h`

            #{provider_commands}

            #### This readme was generated with `abt readme > README.md`
          MD
        end

        private

        def example_commands
          lines = []

          complete_examples.each_with_index do |(title, commands), index|
            lines << "" unless index.zero?
            lines << title

            commands.each do |(command, description)|
              formatted_description = description.nil? ? "" : ": #{description}"
              lines << "- `#{command}`#{formatted_description}"
            end
          end

          lines.join("\n")
        end

        def provider_commands # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          lines = []

          Docs.providers.each_with_index do |(scheme, commands), index|
            lines << "" unless index.zero?
            lines << "### #{inflector.humanize(scheme)}"
            lines << "| Command | Description |"
            lines << "| :------ | :---------- |"

            max_length = commands.values.map(&:first).map(&:length).max

            commands.each do |(_command, (usage, description))|
              adjusted_usage = "`#{usage}`".ljust(max_length + 2)
              lines << "| #{adjusted_usage} | #{description} |"
            end
          end

          lines.join("\n")
        end

        def complete_examples
          Docs.basic_examples.merge(Docs.extended_examples)
        end

        def inflector
          Dry::Inflector.new
        end
      end
    end
  end
end
