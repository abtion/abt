# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Start < BaseCommand

        def call
          Move.new(arg_str: arg_str, cli: cli).call
        end
      end
    end
  end
end
