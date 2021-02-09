# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class BaseCommand < Abt::Cli::BaseCommand
        attr_reader :project_gid, :task_gid, :config

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
          cli.abort 'No current/specified project. Did you initialize Asana?' if project_gid.nil?
        end

        def require_task!
          if project_gid.nil?
            cli.abort 'No current/specified project. Did you initialize Asana and pick a task?'
          end
          cli.abort 'No current/specified task. Did you pick an Asana task?' if task_gid.nil?
        end

        def same_args_as_config?
          project_gid == config.project_gid && task_gid == config.task_gid
        end

        def print_project(project)
          cli.print_provider_command('asana', project['gid'], project['name'])
          cli.warn project['permalink_url'] if project.key?('permalink_url') && cli.output.isatty
        end

        def print_task(project, task)
          project = { 'gid' => project } if project.is_a?(String)
          cli.print_provider_command('asana', "#{project['gid']}/#{task['gid']}", task['name'])
          cli.warn task['permalink_url'] if task.key?('permalink_url') && cli.output.isatty
        end

        def use_current_path
          @project_gid = config.project_gid
          @task_gid = config.task_gid
        end

        def use_path(path)
          args = path.to_s.split('/')
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
