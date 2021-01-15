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
          @project_id = Abt::GitConfig.local('abt.harvest.projectId').to_s
          @project_id = nil if project_id.empty?
          @task_id = Abt::GitConfig.local('abt.harvest.taskId').to_s
          @task_id = nil if task_id.empty?
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
          @api ||= Abt::HarvestClient.new(access_token: config.access_token, account_id: config.account_id)
        end
      end
    end
  end
end
