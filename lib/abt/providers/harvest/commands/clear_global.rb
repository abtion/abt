# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class ClearGlobal < BaseCommand
          def self.command
            'clear-global harvest'
          end

          def self.description
            'Clear all global configuration'
          end

          def call
            cli.warn 'Clearing Harvest project configuration'
            config.clear_global
          end
        end
      end
    end
  end
end
