# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Clear < BaseCommand
          def self.command
            'clear asana'
          end

          def self.description
            'Clear project/task for current git repository'
          end

          def call
            cli.warn 'Clearing Asana project configuration'
            config.clear_local
          end
        end
      end
    end
  end
end
