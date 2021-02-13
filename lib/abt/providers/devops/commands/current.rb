# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Current < BaseCommand
          def self.usage
            'abt current devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]'
          end

          def self.description
            'Get or set DevOps configuration for current git repository'
          end

          def perform
            require_board!

            if path == config.path || !config.local_available?
              show_current_configuration
            else
              cli.warn 'Updating configuration'
              update_configuration
            end
          end

          private

          def show_current_configuration
            if work_item_id.nil?
              print_board(organization_name, project_name, board)
            else
              print_work_item(organization_name, project_name, board, work_item)
            end
          end

          def update_configuration
            ensure_board_is_valid!

            if work_item_id.nil?
              print_board(organization_name, project_name, board)
            else
              ensure_work_item_is_valid!
              print_work_item(organization_name, project_name, board, work_item)
            end

            config.path = path
          end

          def ensure_board_is_valid!
            if board.nil?
              cli.abort 'Board could not be found, ensure that settings for organization, project, and board are correct'
            end
          end

          def ensure_work_item_is_valid!
            cli.abort "No such work item: ##{work_item_id}" if work_item.nil?
          end

          def board
            @board ||= begin
                         cli.warn 'Fetching board...'
                         api.get("work/boards/#{board_id}")
                       rescue HttpError::NotFoundError
                         nil
                       end
          end

          def work_item
            @work_item ||= begin
                             cli.warn 'Fetching work item...'
                             work_item = api.get_paged('wit/workitems', ids: work_item_id)[0]
                             sanitize_work_item(work_item)
                           rescue HttpError::NotFoundError
                             nil
                           end
          end
        end
      end
    end
  end
end
