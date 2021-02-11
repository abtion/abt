# frozen_string_literal: true

module Abt
  class Cli
    class ArgumentsParser
      class SchemeArgument
        attr_reader :scheme, :path, :flags

        def initialize(scheme:, path:, flags:)
          @scheme = scheme
          @path = path
          @flags = flags
        end

        def to_s
          str = scheme
          str += ":#{path}" if path

          [str, *flags].join(' ')
        end
      end
      class SchemeArguments < Array
        def to_s
          map(&:to_s).join(' -- ')
        end
      end

      attr_reader :arguments

      def initialize(arguments)
        @arguments = arguments
      end

      def parse
        result = SchemeArguments.new
        rest = arguments.dup

        until rest.empty?
          (scheme, path) = rest.shift.split(':')
          flags = take_flags(rest)

          result << SchemeArgument.new(scheme: scheme, path: path, flags: flags)
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
