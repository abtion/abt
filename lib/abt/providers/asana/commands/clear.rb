# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Clear < BaseCommand
          def self.usage
            "abt clear asana"
          end

          def self.description
            "Clear asana configuration"
          end

          def self.flags
            [
              ["-g", "--global",
               "Clear global instead of local asana configuration (credentials etc.)"],
              ["-a", "--all", "Clear all asana configuration"]
            ]
          end

          def perform
            abort("Flags --global and --all cannot be used together") if flags[:global] && flags[:all]

            config.clear_local unless flags[:global]
            config.clear_global if flags[:global] || flags[:all]

            warn("Configuration cleared")
          end
        end
      end
    end
  end
end
