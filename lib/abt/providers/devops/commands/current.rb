# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Current < BaseCommand
          def self.command
            'current devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]'
          end

          def self.description
            'Get or set DevOps configuration for current git repository'
          end

          def call
            if same_args_as_config? || !config.local_available?
              show_current_configuration
            else
              cli.warn 'Updating configuration'
              update_configuration
            end
          end

          private

          def show_current_configuration
            if organization_name.nil?
              cli.warn 'No organization selected'
            elsif project_name.nil?
              cli.warn 'No project selected'
            elsif board_id.nil?
              cli.warn 'No board selected'
            elsif work_item_id.nil?
              print_board(organization_name, project_name, board)
            else
              print_work_item(organization_name, project_name, board, work_item)
            end
          end

          def update_configuration
            ensure_board_is_valid!

            if work_item_id.nil?
              update_board_config
              config.work_item_id = nil

              print_board(organization_name, project_name, board)
            else
              ensure_work_item_is_valid!

              update_board_config
              config.work_item_id = work_item_id

              print_work_item(organization_name, project_name, board, work_item)
            end
          end

          def update_board_config
            config.organization_name = organization_name
            config.project_name = project_name
            config.board_id = board_id
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