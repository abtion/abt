# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Pick < BaseCommand
          def self.usage
            "abt pick devops[:<organization-name>/<project-name>/<board-id>]"
          end

          def self.description
            "Pick work item for current git repository"
          end

          def self.flags
            [
              ["-d", "--dry-run", "Keep existing configuration"],
              ["-c", "--clean", "Don't reuse project/board configuration"]
            ]
          end

          def perform
            pick!

            print_work_item(organization_name, project_name, board, work_item)

            return if flags[:"dry-run"]

            if config.local_available?
              update_config(work_item)
            else
              warn("No local configuration to update - will function as dry run")
            end
          end

          private

          def pick!
            prompt_project! if project_name.nil? || flags[:clean]
            prompt_board! if board_id.nil? || flags[:clean]
            prompt_work_item!
          end

          def update_config(work_item)
            config.path = Path.from_ids(
              organization_name: organization_name,
              project_name: project_name,
              board_id: board_id,
              work_item_id: work_item["id"]
            )
          end
        end
      end
    end
  end
end
