# frozen_string_literal: true

module Abt
  class Cli
    class BaseCommand
      def self.usage
        raise NotImplementedError, 'Command classes must implement .command'
      end

      def self.description
        raise NotImplementedError, 'Command classes must implement .description'
      end

      def self.flags
        []
      end

      attr_reader :path, :flags, :cli

      def initialize(path:, flags:, cli:)
        @cli = cli
        @path = path
        @flags = parse_flags(flags)
      end

      def perform
        raise NotImplementedError, 'Command classes must implement #perform'
      end

      private

      def parse_flags(flags)
        result = {}

        flag_parser.parse!(flags.dup, into: result)

        cli.exit_with_message(flag_parser.help) if result[:help]

        result
      rescue OptionParser::InvalidOption => e
        cli.abort e.message
      end

      def flag_parser
        @flag_parser ||= OptionParser.new do |opts|
          opts.banner = <<~TXT
            #{self.class.description}

            Usage: #{self.class.usage}
          TXT

          opts.on('-h', '--help')

          self.class.flags.each do |(*flag)|
            opts.on(*flag)
          end
        end
      end
    end
  end
end
