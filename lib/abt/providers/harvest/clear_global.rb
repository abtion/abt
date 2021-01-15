# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class ClearGlobal < BaseCommand
        def self.command
          'clear-global harvest'
        end

        def self.description
          'Clear all global configuration'
        end

        def call
          cli.warn 'Clearing Harvest project configuration'
          Harvest.clear_global
        end
      end
    end
  end
end
