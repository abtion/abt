# frozen_string_literal: true

module Abt
  class Cli
    class ArgumentsParser
      class ProviderArgument
        attr_reader :uri, :flags

        def initialize(uri:, flags:)
          @uri = uri
          @flags = flags
        end

        def to_s
          [@uri, *flags].join(' ')
        end
      end

      class ProviderArguments < Array
        def to_s
          map(&:to_s).join(' -- ')
        end
      end

      attr_reader :arguments

      def initialize(arguments)
        @arguments = arguments
      end

      def parse
        result = ProviderArguments.new

        rest = arguments.dup
        @provider_args = []

        until rest.empty?
          uri = rest.shift
          flags = take_flags(rest)

          result << ProviderArgument.new(uri: uri, flags: flags)
        end

        result
      end

      private

      def take_flags(rest)
        flags = []

        if flag?(rest.first)
          flags << rest.shift until rest.empty? || delimiter?(rest.first)
          rest.shift if delimiter?(rest.first)
        end

        flags
      end

      def flag?(part)
        part && part[0] == '-'
      end

      def delimiter?(part)
        part == '--'
      end
    end
  end
end
