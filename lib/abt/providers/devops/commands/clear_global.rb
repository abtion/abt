# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class ClearGlobal < BaseCommand
          def self.command
            'clear-global devops'
          end

          def self.description
            'Clear all global configuration'
          end

          def call
            cli.warn 'Clearing global DevOps configuration'
            config.clear_global
          end
        end
      end
    end
  end
end
