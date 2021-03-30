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

            print_work_item(organization_name, project_name, team_name, board, work_item)

            return if flags[:"dry-run"]

            if config.local_available?
              config.path = path
            else
              warn("No local configuration to update - will function as dry run")
            end
          end

          private

          def pick!
            prompt_board! if board_name.nil? || flags[:clean]
            prompt_work_item!
          end
        end
      end
    end
  end
end
