# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Clear < BaseCommand
          def self.usage
            'abt clear asana'
          end

          def self.description
            'Clear project/task for current git repository'
          end

          def perform
            cli.warn 'Clearing Asana project configuration'
            config.clear_local
          end
        end
      end
    end
  end
end
