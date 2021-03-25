# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Current < BaseCommand
          def self.usage
            "abt current devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]"
          end

          def self.description
            "Get or set DevOps configuration for current git repository"
          end

          def perform
            require_local_config!
            require_board!
            ensure_valid_configuration!

            if path != config.path && config.local_available?
              config.path = path
              warn("Configuration updated")
            end

            print_configuration
          end

          private

          def print_configuration
            if work_item_id.nil?
              print_board(organization_name, project_name, board)
            else
              print_work_item(organization_name, project_name, board, work_item)
            end
          end

          def ensure_valid_configuration!
            if board.nil?
              abort("Board could not be found, ensure that settings for organization, project, and board are correct")
            end
            abort("No such work item: ##{work_item_id}") if work_item_id && work_item.nil?
          end
        end
      end
    end
  end
end
