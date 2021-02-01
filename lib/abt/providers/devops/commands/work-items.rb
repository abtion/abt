# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class WorkItems < BaseCommand
          def self.command
            'work-items devops'
          end

          def self.description
            'List all work items on board - useful for piping into grep etc.'
          end

          def call
            require_board!

            work_items.each do |work_item|
              print_work_item(organization_name, project_name, board, work_item)
            end
          end

          private

          def work_items
            @work_items ||= begin
              cli.warn 'Fetching work items...'
              api.work_item_query(
                <<~WIQL
                  SELECT [System.Id]
                  FROM WorkItems
                  ORDER BY [System.Title] ASC
                WIQL
              ).map { |work_item| sanitize_work_item(work_item) }
            end
          end

          def board
            @board ||= api.get("work/boards/#{board_id}")
          end
        end
      end
    end
  end
end
