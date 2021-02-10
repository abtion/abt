# frozen_string_literal: true

module Abt
  module Docs
    module Cli
      class << self
        def help
          <<~TXT
            Usage: #{usage_line}

            #{formatted_examples(Docs.basic_examples)}

            For detailed examples/commands try:
               abt examples
               abt commands
          TXT
        end

        def examples
          <<~TXT
            Printing examples

            #{formatted_examples(Docs.basic_examples)}

            #{formatted_examples(Docs.extended_examples)}
          TXT
        end

        def commands
          <<~TXT
            Printing commands

            Run commands with --help flag to see detailed usage and flags, e.g.:
               abt track harvest -h

            #{providers_commands}
          TXT
        end

        private

        def usage_line
          'abt <command> [<provider-URI>] [<flags> --] [<provider-URI>] ...'
        end

        def formatted_examples(example_groups)
          lines = []

          example_groups.each_with_index do |(title, examples), index|
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

            commands_definition.each do |(command, (_usage, description))|
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
