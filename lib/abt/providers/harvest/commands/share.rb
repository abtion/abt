# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Share < BaseCommand
          def self.usage
            'abt share harvest[:<project-id>[/<task-id>]]'
          end

          def self.description
            'Print project/task ARI'
          end

          def perform
            require_project!

            cli.print_ari('harvest', path)
          end
        end
      end
    end
  end
end
