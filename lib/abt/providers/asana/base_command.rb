# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class BaseCommand
        attr_reader :arg_str, :project_gid, :task_gid, :cli

        def initialize(arg_str:, cli:)
          @arg_str = arg_str

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
        end

        def print_task(project, task)
          cli.print_provider_command('asana', "#{project['gid']}/#{task['gid']}", task['name'])
        end

        def use_current_args
          @project_gid = Abt::GitConfig.local('abt.asana.projectGid').to_s
          @project_gid = nil if project_gid.empty?
          @task_gid = Abt::GitConfig.local('abt.asana.taskGid').to_s
          @task_gid = nil if task_gid.empty?
        end

        def use_arg_str(arg_str)
          args = arg_str.to_s.split('/')
          @project_gid = args[0].to_s
          @project_gid = nil if project_gid.empty?

          return if project_gid.nil?

          @task_gid = args[1].to_s
          @task_gid = nil if @task_gid.empty?
        end

        def remember_project_gid(project_gid)
          Abt::GitConfig.local('abt.asana.projectGid', project_gid)
        end

        def remember_task_gid(task_gid)
          if task_gid.nil?
            Abt::GitConfig.unset_local('abt.asana.taskGid')
          else
            Abt::GitConfig.local('abt.asana.taskGid', task_gid)
          end
        end
      end
    end
  end
end
