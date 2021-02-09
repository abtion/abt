# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Clear < BaseCommand
          def self.usage
            'abt clear devops'
          end

          def self.description
            'Clear DevOps config for current git repository'
          end

          def perform
            cli.warn 'Clearing configuration'
            config.clear_local
          end
        end
      end
    end
  end
end
