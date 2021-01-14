# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class ClearGlobal < BaseCommand
          def self.command
            'clear-global asana'
          end

          def self.description
            'Clear all global configuration'
          end

          def call
            cli.warn 'Clearing Asana project configuration'
            config.clear_global
          end
        end
      end
    end
  end
end
