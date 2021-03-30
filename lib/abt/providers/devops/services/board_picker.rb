# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Services
        class BoardPicker
          class Result
            attr_reader :board, :path

            def initialize(board:, path:)
              @board = board
              @path = path
            end
          end

          def self.call(**args)
            new(**args).call
          end

          attr_reader :cli, :config, :path

          def initialize(cli:, config:)
            @cli = cli
            @config = config
          end

          def call
            @path = ProjectPicker.call(cli: cli).path
            board = cli.prompt.choice("Select a project work board", boards)

            Result.new(board: board, path: path_with_board(team, board))
          end

          private

          def path_with_board(team, board)
            Path.from_ids(
              organization_name: path.organization_name,
              project_name: path.project_name,
              team_name: Api.rfc_3986_encode_path_segment(team["name"]),
              board_name: Api.rfc_3986_encode_path_segment(board["name"])
            )
          end

          def team
            @team ||= cli.prompt.choice("Select a team", teams)
          end

          def teams
            @teams ||= api.get_paged("/_apis/projects/#{path.project_name}/teams")
          end

          def boards
            team_name = Api.rfc_3986_encode_path_segment(team["name"])
            @boards ||= api.get_paged("#{path.project_name}/#{team_name}/_apis/work/boards")
          end

          def api
            Api.new(organization_name: path.organization_name,
                    username: config.username_for_organization(path.organization_name),
                    access_token: config.access_token_for_organization(path.organization_name),
                    cli: cli)
          end
        end
      end
    end
  end
end
