# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Pick < BaseCommand
          def self.usage
            'abt pick devops[:<organization-name>/<project-name>/<board-id>]'
          end

          def self.description
            'Pick work item for current git repository'
          end

          def self.flags
            [
              ['-d', '--dry-run', 'Keep existing configuration']
            ]
          end

          def perform
            cli.abort 'Must be run inside a git repository' unless config.local_available?
            require_board!

            cli.warn "#{project_name} - #{board['name']}"

            work_item = select_work_item
            print_work_item(organization_name, project_name, board, work_item)

            return if flags[:"dry-run"]

            config.path = Path.from_ids(organization_name, project_name, board_id, work_item['id'])
          end

          private

          def select_work_item
            loop do
              column = cli.prompt.choice 'Which column?', columns
              cli.warn 'Fetching work items...'
              work_items = work_items_in_column(column)

              if work_items.length.zero?
                cli.warn 'Section is empty'
                next
              end

              work_item = cli.prompt.choice 'Select a work item', work_items, true
              return work_item if work_item
            end
          end

          def work_items_in_column(column)
            work_items = api.work_item_query(
              <<~WIQL
                SELECT [System.Id]
                FROM WorkItems
                WHERE [System.BoardColumn] = '#{column['name']}'
                ORDER BY [Microsoft.VSTS.Common.BacklogPriority] ASC
              WIQL
            )

            work_items.map { |work_item| sanitize_work_item(work_item) }
          end

          def columns
            board['columns']
          end

          def board
            @board ||= api.get("work/boards/#{board_id}")
          end
        end
      end
    end
  end
end
