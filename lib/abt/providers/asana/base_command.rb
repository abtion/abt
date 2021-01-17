# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class BaseCommand
        attr_reader :arg_str, :project_gid, :task_gid, :cli, :config

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
          cli.print_provider_command('asana', project['gid'], project['name'])
          cli.warn project['permalink_url'] if project.key?('permalink_url') && cli.output.isatty
        end

        def print_task(project, task)
          project = { 'gid' => project } if project.is_a?(String)
          cli.print_provider_command('asana', "#{project['gid']}/#{task['gid']}", task['name'])
          cli.warn task['permalink_url'] if task.key?('permalink_url') && cli.output.isatty
        end

        def use_current_args
          @project_gid = config.project_gid
          @task_gid = config.task_gid
        end

        def use_arg_str(arg_str)
          args = arg_str.to_s.split('/')
          @project_gid = args[0].to_s
          @project_gid = nil if project_gid.empty?

          return if project_gid.nil?

          @task_gid = args[1].to_s
          @task_gid = nil if @task_gid.empty?
        end

        def api
          Abt::Providers::Asana::Api.new(access_token: config.access_token)
        end
      end
    end
  end
end
