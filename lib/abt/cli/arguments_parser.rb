# frozen_string_literal: true

module Abt
  class Cli
    class ArgumentsParser
      attr_reader :arguments

      def initialize(arguments)
        @arguments = arguments
      end

      def parse
        result = Abt::Cli::AriList.new
        rest = arguments.dup

        until rest.empty?
          (scheme, path) = rest.shift.split(':')
          flags = take_flags(rest)

          result << Abt::Cli::Ari.new(scheme: scheme, path: path, flags: flags)
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
