# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Start < BaseCommand
        def call
          Current.new(arg_str: arg_str, cli: cli).call unless arg_str.nil?
          Move.new(arg_str: arg_str, cli: cli).call
        end
      end
    end
  end
end
