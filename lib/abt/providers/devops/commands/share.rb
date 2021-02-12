# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Share < BaseCommand
          def self.usage
            'abt share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]'
          end

          def self.description
            'Print DevOps ARI'
          end

          def perform
            require_work_item!

            args = [organization_name, project_name, board_id, work_item_id].compact
            cli.print_ari('devops', args.join('/'))
          end
        end
      end
    end
  end
end
