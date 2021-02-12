# frozen_string_literal: true

module Abt
  class Cli
    class Ari
      attr_reader :scheme, :path, :flags

      def initialize(scheme:, path:, flags: [])
        @scheme = scheme
        @path = path
        @flags = flags
      end

      def without_flags
        self.class.new(scheme: scheme, path: path)
      end

      def to_s
        str = scheme
        str += ":#{path}" if path

        [str, *flags].join(' ')
      end
    end
  end
end
