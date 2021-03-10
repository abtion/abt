# frozen_string_literal: true

module Abt
  class BaseCommand
    extend Forwardable

    def self.usage
      raise NotImplementedError, "Command classes must implement .usage"
    end

    def self.description
      raise NotImplementedError, "Command classes must implement .description"
    end

    def self.flags
      []
    end

    attr_reader :ari, :cli, :flags

    def_delegators(:@cli, :warn, :puts, :print, :abort, :exit_with_message)

    def initialize(ari:, cli:)
      @cli = cli
      @ari = ari
      @flags = parse_flags(ari.flags)
    end

    def perform
      raise NotImplementedError, "Command classes must implement #perform"
    end

    private

    def parse_flags(flags)
      result = {}

      flag_parser.parse!(flags.dup, into: result)

      exit_with_message(flag_parser.help) if result[:help]

      result
    rescue OptionParser::InvalidOption => e
      abort(e.message)
    end

    def flag_parser
      @flag_parser ||= OptionParser.new do |opts|
        opts.banner = <<~TXT
          #{self.class.description}

          Usage: #{self.class.usage}
        TXT

        opts.on("-h", "--help", "Display this help")

        self.class.flags.each do |(*flag)|
          opts.on(*flag)
        end
      end
    end
  end
end
