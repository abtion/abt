# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Clear < BaseCommand
          def self.usage
            'abt clear harvest'
          end

          def self.description
            'Clear harvest configuration'
          end

          def self.flags
            [
              ['-g', '--global', 'Clear global instead of local harvest configuration (credentials etc.)'],
              ['-a', '--all', 'Clear all harvest configuration']
            ]
          end

          def perform
            if flags[:global] && flags[:all]
              abort('Flags --global and --all cannot be used at the same time')
            end

            config.clear_local unless flags[:global]
            config.clear_global if flags[:global] || flags[:all]

            warn 'Configuration cleared'
          end
        end
      end
    end
  end
end
