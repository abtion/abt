# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class BaseCommand < Abt::Cli::BaseCommand
        attr_reader :path, :flags, :project_id, :task_id, :cli, :config

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
          cli.print_scheme_argument(
            'harvest',
            project['id'],
            "#{project['client']['name']} > #{project['name']}"
          )
        end

        def print_task(project, task)
          cli.print_scheme_argument(
            'harvest',
            "#{project['id']}/#{task['id']}",
            "#{project['name']} > #{task['name']}"
          )
        end

        def use_current_path
          @project_id = config.project_id
          @task_id = config.task_id
        end

        def use_path(path)
          args = path.to_s.split('/')
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
