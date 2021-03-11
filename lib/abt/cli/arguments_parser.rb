# frozen_string_literal: true

module Abt
  class Cli
    class ArgumentsParser
      attr_reader :arguments

      def initialize(arguments)
        @arguments = arguments
      end

      def parse
        result = AriList.new
        rest = arguments.dup

        # If the first arg is a flag, it's for a global command
        result << Ari.new(flags: take_flags(rest)) if flag?(rest.first)

        until rest.empty?
          (scheme, path) = rest.shift.split(":")
          flags = take_flags(rest)

          result << Ari.new(scheme: scheme, path: path, flags: flags)
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
        part && part[0] == "-"
      end

      def delimiter?(part)
        part == "--"
      end
    end
  end
end
