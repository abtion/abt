# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class BaseCommand
        attr_reader :arg_str, :organization_name, :project_name, :board_id, :work_item_id, :cli, :config

        def initialize(arg_str:, cli:)
          @arg_str = arg_str

          @config = Configuration.new(cli: cli)

          if arg_str.nil?
            use_current_args
          else
            use_arg_str(arg_str)
          end

          @cli = cli
        end

        private

        def same_args_as_config?
          organization_name == config.organization_name &&
            project_name == config.project_name &&
            board_id == config.board_id &&
            work_item_id == config.work_item_id
        end

        def print_board(organization_name, project_name, board)
          arg_str = "#{organization_name}/#{project_name}/#{board['id']}"

          cli.print_provider_command('devops', arg_str, board['name'])
          # cli.warn board['url'] if board.key?('url') && cli.output.isatty # TODO: Web URL
        end

        def print_work_item(organization, project, board, work_item)
          arg_str = "#{organization}/#{project}/#{board['id']}/#{work_item['id']}"

          cli.print_provider_command('devops', arg_str, work_item['name'])
        end

        def use_current_args
          @organization_name = config.organization_name
          @project_name = config.project_name
          @board_id = config.board_id
          @work_item_id = config.work_item_id
        end

        def use_arg_str(arg_str)
          args = arg_str.to_s.split('/')

          if args.length < 3
            cli.abort 'Argument format is <organization>/<project>/<board-id>[/<work-item-id>]'
          end

          (@organization_name, @project_name, @board_id, @work_item_id) = args
        end

        def api
          Abt::Providers::Devops::Api.new(organization_name: organization_name,
                                          project_name: project_name,
                                          username: config.username_for_organization(organization_name),
                                          access_token: config.access_token_for_organization(organization_name))
        end
      end
    end
  end
end
