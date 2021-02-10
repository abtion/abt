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
            'Clear asana configuration'
          end

          def self.flags
            [
              ['-g', '--global', 'Clear global instead of local asana configuration (credentials etc.)'],
              ['-a', '--all', 'Clear all asana configuration']
            ]
          end

          def perform
            if flags[:global] && flags[:all]
              abort('Flags --global and --all cannot be used at the same time')
            end

            config.clear_local unless flags[:global]
            config.clear_global if flags[:global] || flags[:all]
          end
        end
      end
    end
  end
end
