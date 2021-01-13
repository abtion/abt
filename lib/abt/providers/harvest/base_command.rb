# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class BaseCommand
        attr_reader :arg_str, :project_id, :task_id, :cli

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

        def remember_project_id(project_id)
          Abt::GitConfig.local('abt.harvest.projectId', project_id)
        end

        def remember_task_id(task_id)
          if task_id.nil?
            Abt::GitConfig.unset_local('abt.harvest.taskId')
          else
            Abt::GitConfig.local('abt.harvest.taskId', task_id)
          end
        end
      end
    end
  end
end
