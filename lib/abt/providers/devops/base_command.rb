# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class BaseCommand < Abt::Cli::BaseCommand
        attr_reader :organization_name, :project_name, :board_id, :work_item_id, :config

        def initialize(path:, cli:, **)
          super

          @config = Configuration.new(cli: cli)

          if path.nil?
            use_current_path
          else
            use_path(path)
          end
        end

        private

        def require_board!
          return if organization_name && project_name && board_id

          cli.abort 'No current/specified board. Did you initialize DevOps?'
        end

        def require_work_item!
          unless organization_name && project_name && board_id
            cli.abort 'No current/specified board. Did you initialize DevOps and pick a work item?'
          end

          return if work_item_id

          cli.abort 'No current/specified work item. Did you pick a DevOps work item?'
        end

        def sanitize_work_item(work_item)
          return nil if work_item.nil?

          work_item.merge(
            'id' => work_item['id'].to_s,
            'name' => work_item['fields']['System.Title'],
            'url' => api.url_for_work_item(work_item)
          )
        end

        def same_args_as_config?
          organization_name == config.organization_name &&
            project_name == config.project_name &&
            board_id == config.board_id &&
            work_item_id == config.work_item_id
        end

        def print_board(organization_name, project_name, board)
          path = "#{organization_name}/#{project_name}/#{board['id']}"

          cli.print_scheme_argument('devops', path, board['name'])
          # cli.warn board['url'] if board.key?('url') && cli.output.isatty # TODO: Web URL
        end

        def print_work_item(organization, project, board, work_item)
          path = "#{organization}/#{project}/#{board['id']}/#{work_item['id']}"

          cli.print_scheme_argument('devops', path, work_item['name'])
          cli.warn work_item['url'] if work_item.key?('url') && cli.output.isatty
        end

        def use_current_path
          @organization_name = config.organization_name
          @project_name = config.project_name
          @board_id = config.board_id
          @work_item_id = config.work_item_id
        end

        def use_path(path)
          args = path.to_s.split('/')

          if args.length < 3
            cli.abort 'Argument format is <organization>/<project>/<board-id>[/<work-item-id>]'
          end

          (@organization_name, @project_name, @board_id, @work_item_id) = args
        end

        def api
          Abt::Providers::Devops::Api.new(organization_name: organization_name,
                                          project_name: project_name,
                                          username: config.username_for_organization(organization_name),
                                          access_token: config.access_token_for_organization(organization_name),
                                          cli: cli)
        end
      end
    end
  end
end
