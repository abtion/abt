# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Services
        class WorkItemPicker
          class Result
            attr_reader :work_item, :path

            def initialize(work_item:, path:)
              @work_item = work_item
              @path = path
            end
          end

          def self.call(**args)
            new(**args).call
          end

          attr_reader :cli, :config, :path, :board

          def initialize(cli:, path:, config:, board:)
            @cli = cli
            @config = config
            @path = path
            @board = board
          end

          def call
            work_item = select_work_item

            path_with_work_item = Path.from_ids(
              organization_name: path.organization_name,
              project_name: path.project_name,
              team_name: path.team_name,
              board_name: path.board_name,
              work_item_id: work_item["id"]
            )

            Result.new(work_item: work_item, path: path_with_work_item)
          end

          def select_work_item
            column = cli.prompt.choice("Which column in #{board['name']}?", columns)
            cli.warn("Fetching work items...")
            work_items = work_items_in_column(column)

            if work_items.length.zero?
              cli.warn("Section is empty")
              select_work_item
            else
              prompt_work_item(work_items) || select_work_item
            end
          end

          def prompt_work_item(work_items)
            options = work_items.map do |work_item|
              {
                "id" => work_item["id"],
                "name" => "##{work_item['id']} #{work_item['name']}"
              }
            end

            choice = cli.prompt.choice("Select a work item", options, nil_option: true)
            choice && work_items.find { |work_item| work_item["id"] == choice["id"] }
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

            work_items.map { |work_item| api.sanitize_work_item(work_item) }
          end

          def columns
            board["columns"] ||
              api.get("#{path.project_name}/#{path.team_name}/_apis/work/boards/#{path.board_name}")["columns"]
          end

          private

          def api
            Abt::Providers::Devops::Api.new(organization_name: path.organization_name,
                                            username: config.username_for_organization(path.organization_name),
                                            access_token: config.access_token_for_organization(path.organization_name),
                                            cli: cli)
          end
        end
      end
    end
  end
end
