# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Clear < BaseCommand
          def self.usage
            "abt clear devops"
          end

          def self.description
            "Clear DevOps configuration"
          end

          def self.flags
            [
              ["-g", "--global",
               "Clear global instead of local DevOp configuration (credentials etc.)"],
              ["-a", "--all", "Clear all DevOp configuration"]
            ]
          end

          def perform
            abort("Flags --global and --all cannot be used at the same time") if flags[:global] && flags[:all]

            config.clear_local unless flags[:global]
            config.clear_global if flags[:global] || flags[:all]

            warn("Configuration cleared")
          end
        end
      end
    end
  end
end
