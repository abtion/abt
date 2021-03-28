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

          def initialize(cli:, path:, config:)
            @cli = cli
            @config = config
            @path = path
          end

          def call
            board = cli.prompt.choice("Select a project work board", boards)

            path_with_board = Path.from_ids(
              organization_name: path.organization_name,
              project_name: path.project_name,
              board_id: board["id"]
            )

            Result.new(board: board, path: path_with_board)
          end

          private

          def boards
            @boards ||= api.get_paged("work/boards")
          end

          def api
            Abt::Providers::Devops::Api.new(organization_name: path.organization_name,
                                            project_name: path.project_name,
                                            username: config.username_for_organization(path.organization_name),
                                            access_token: config.access_token_for_organization(path.organization_name),
                                            cli: cli)
          end
        end
      end
    end
  end
end
