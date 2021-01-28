# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Pick < BaseCommand
          def self.command
            'pick devops[:<organization_name>/<project_name>/<board-id>]'
          end

          def self.description
            'Pick work item for current git repository'
          end

          def call
            cli.abort 'Must be run inside a git repository' unless config.local_available?

            cli.warn "#{project_name} - #{board['name']}"

            work_item = select_work_item

            # We might have gotten org, project, board as arg str
            config.organization_name = organization_name
            config.project_name = project_name
            config.board_id = board_id
            config.work_item_id = work_item['id']

            print_work_item(organization_name, project_name, board, work_item)
          end

          private

          def select_work_item
            loop do
              column = cli.prompt_choice 'Which column?', columns
              cli.warn 'Fetching work items...'
              work_items = work_items_in_column(column)

              if work_items.length.zero?
                cli.warn 'Section is empty'
                next
              end

              work_item = cli.prompt_choice 'Select a work item', work_items, true
              return work_item if work_item
            end
          end

          def work_items_in_column(column)
            wiql = <<~WIQL
              SELECT [System.Id]
              FROM WorkItems
              WHERE [System.BoardColumn] = '#{column['name']}'
              ORDER BY [Microsoft.VSTS.Common.BacklogPriority] ASC
            WIQL

            response = api.post('wit/wiql', Oj.dump({ query: wiql }, mode: :json))
            ids = response['workItems'].map { |work_item| work_item['id'] }
            work_items = api.get_paged('wit/workitems', ids: ids.join(','))

            work_items.map { |work_item| sanitize_work_item(work_item) }
          end

          def columns
            board['columns']
          end

          def board
            @boards ||= api.get("work/boards/#{board_id}")
          end
        end
      end
    end
  end
end
