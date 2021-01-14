# frozen_string_literal: true

module Abt
  class Cli
    module Io
      %i[puts print].each do |method_name|
        define_method(method_name) do |*args|
          output.puts(*args)
        end
      end

      def warn(*args)
        err_output.puts(*args)
      end

      def abort(message)
        raise AbortError, message
      end
    end
  end
end
