# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class << self
        def parse_arg_string(arg_string)
          args = arg_string.to_s.split('/')

          project_id = args[0].to_s
          if project_id.empty?
            project_id = Abt::GitConfig.local('abt.harvest.projectId').to_s
          end
          project_id = nil if project_id.empty?

          task_id = args[1].to_s
          if task_id.empty?
            task_id = Abt::GitConfig.local('abt.harvest.taskId').to_s
          end
          task_id = nil if project_id.empty?

          { project_id: project_id, task_id: task_id }
        end

        def store_args(args)
          Abt::GitConfig.local('abt.harvest.projectId', args[:project_id])
          Abt::GitConfig.local('abt.harvest.taskId', args[:task_id])
          true
        end
      end
    end
  end
end
