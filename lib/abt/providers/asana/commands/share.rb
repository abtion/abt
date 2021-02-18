# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Share < BaseCommand
          def self.usage
            'abt share asana[:<project-gid>[/<task-gid>]]'
          end

          def self.description
            'Print project/task ARI'
          end

          def perform
            require_project!

            cli.print_ari('asana', path)
          end
        end
      end
    end
  end
end
