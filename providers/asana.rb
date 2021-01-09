# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class << self
        def parse_arg_string(arg_string)
          args = arg_string.to_s.split('/')

          project_gid = args[0].to_s
          if project_gid.empty?
            project_gid = Abt::GitConfig.local('abt.asana.projectGid')
          end
          project_gid = nil if project_gid.empty?

          task_gid = args[1].to_s
          if task_gid.empty?
            task_gid = Abt::GitConfig.local('abt.asana.taskGid').to_s
          end
          task_gid = nil if project_gid.empty?

          { project_gid: project_gid, task_gid: task_gid }
        end

        def store_args(args)
          Abt::GitConfig.local('abt.asana.projectGid', args[:project_gid])
          Abt::GitConfig.local('abt.asana.taskGid', args[:task_gid])
          true
        end

        def workspace_gid
          @workspace_gid ||= begin
            current = Abt::GitConfig.global('abt.asana.workspaceGid')
            if current.nil?
              workspaces = asana.get_paged('workspaces')
              if workspaces.empty?
                abort 'Your asana access token does not have access to any workspaces'
              end

              # TODO: Handle if there are multiple workspaces
              Abt::GitConfig.global('abt.asana.workspaceGid', workspaces.first['gid'])
            else
              current
            end
          end
        end

        private

        def asana
          Abt::Asana::Client
        end
      end
    end
  end
end