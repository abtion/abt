# frozen_string_literal: true

module Abt
  class Cli
    class BaseCommand
      def self.usage
        raise NotImplementedError, 'Command classes must implement .command method'
      end

      def self.description
        raise NotImplementedError, 'Command classes must implement .description method'
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

      private

      def parse_flags(flags)
        result = {}
        OptionParser.new do |opts|
          opts.banner = banner

          self.class.flags.each do |(*flag)|
            opts.on(*flag)
          end
        end.parse!(flags, into: result)

        result
      rescue OptionParser::InvalidOption => e
        cli.abort e.message
      end

      def banner
        <<~TXT
          #{self.class.description}

          Usage: #{self.class.usage}
        TXT
      end
    end
  end
end
