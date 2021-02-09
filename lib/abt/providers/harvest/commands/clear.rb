# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Clear < BaseCommand
          def self.command
            'clear harvest'
          end

          def self.description
            'Clear project/task for current git repository'
          end

          def perform
            cli.warn 'Clearing Harvest project configuration'
            config.clear_local
          end
        end
      end
    end
  end
end
