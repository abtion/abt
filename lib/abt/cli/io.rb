# frozen_string_literal: true

module Abt
  class Cli
    module Io
      def warn(*args)
        err_output.puts(*args)
      end

      def puts(*args)
        output.puts(*args)
      end

      def print(*args)
        output.print(*args)
      end

      def abort(message)
        raise AbortError, message
      end
    end
  end
end
