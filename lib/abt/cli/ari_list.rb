# frozen_string_literal: true

module Abt
  class Cli
    class AriList < Array
      def to_s
        map(&:to_s).join(' -- ')
      end

      def -(other)
        AriList.new(to_a - other)
      end
    end
  end
end
