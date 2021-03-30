# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class BaseCommand < Abt::BaseCommand
        extend Forwardable

        attr_reader :config, :path

        def_delegators(:@path, :organization_name, :project_name, :team_name, :board_name, :work_item_id)

        def initialize(ari:, cli:)
          super

          @config = Configuration.new(cli: cli)
          @path = ari.path ? Path.new(ari.path) : config.path
        end

        private

        def require_local_config!
          abort("Must be run inside a git repository") unless config.local_available?
        end

        def require_board!
          return if board_name && organization_name && project_name && team_name

          abort("No current/specified board. Did you forget to `pick`?")
        end

        def require_work_item!
          require_board!
          return if work_item_id

          abort("No current/specified work item. Did you forget to `pick`?")
        end

        def prompt_board!
          result = Services::BoardPicker.call(cli: cli, config: config)
          @path = result.path
          @board = result.board
        end

        def prompt_work_item!
          result = Services::WorkItemPicker.call(cli: cli, path: path, config: config, board: board)
          @path = result.path
          @work_item = result.work_item
        end

        def board
          @board ||= begin
            api.get("#{project_name}/#{team_name}/_apis/work/boards/#{board_name}")
          rescue HttpError::NotFoundError
            nil
          end
        end

        def work_item
          @work_item ||= begin
            work_item = api.get_paged("_apis/wit/workitems", ids: work_item_id)[0]
            api.sanitize_work_item(work_item)
          rescue HttpError::NotFoundError
            nil
          end
        end

        def print_board(organization_name, project_name, team_name, board)
          board_name = Api.rfc_3986_encode_path_segment(board["name"])
          path = "#{organization_name}/#{project_name}/#{team_name}/#{board_name}"

          cli.print_ari("devops", path, board["name"])
          warn(api.url_for_board(project_name, team_name, board)) if cli.output.isatty
        end

        def print_work_item(organization, project, team_name, board, work_item)
          board_name = Api.rfc_3986_encode_path_segment(board["name"])
          path = "#{organization}/#{project}/#{team_name}/#{board_name}/#{work_item['id']}"

          cli.print_ari("devops", path, work_item["name"])
          warn(work_item["url"]) if work_item.key?("url") && cli.output.isatty
        end

        def api
          Api.new(organization_name: organization_name,
                  username: config.username_for_organization(organization_name),
                  access_token: config.access_token_for_organization(organization_name),
                  cli: cli)
        end
      end
    end
  end
end
