# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class BaseCommand
        attr_reader :arg_str, :project_id, :task_id, :cli, :config

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

        def require_project!
          cli.abort 'No current/specified project. Did you initialize Harvest?' if project_id.nil?
        end

        def require_task!
          if project_id.nil?
            cli.abort 'No current/specified project. Did you initialize Harvest and pick a task?'
          end
          cli.abort 'No current/specified task. Did you pick a Harvest task?' if task_id.nil?
        end

        def same_args_as_config?
          project_id == config.project_id && task_id == config.task_id
        end

        def print_project(project)
          cli.print_provider_command(
            'harvest',
            project['id'],
            "#{project['client']['name']} > #{project['name']}"
          )
        end

        def print_task(project, task)
          cli.print_provider_command(
            'harvest',
            "#{project['id']}/#{task['id']}",
            "#{project['name']} > #{task['name']}"
          )
        end

        def use_current_args
          @project_id = config.project_id
          @task_id = config.task_id
        end

        def use_arg_str(arg_str)
          args = arg_str.to_s.split('/')
          @project_id = args[0].to_s
          @project_id = nil if project_id.empty?

          return if project_id.nil?

          @task_id = args[1].to_s
          @task_id = nil if @task_id.empty?
        end

        def api
          @api ||= Abt::Providers::Harvest::Api.new(access_token: config.access_token,
                                                    account_id: config.account_id)
        end
      end
    end
  end
end
