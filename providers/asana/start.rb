# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Start
        attr_reader :arg_str, :cli

        def initialize(arg_str:, cli:)
          @arg_str = arg_str
          @cli = cli
        end

        def call
          Move.new(arg_str: arg_str, cli: cli).call
        end
      end
    end
  end
end
