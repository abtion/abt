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

      class << self
        def workspace_gid
          @workspace_gid ||= begin
            current = Abt::GitConfig.global('abt.asana.workspaceGid')
            if current.nil?
              prompt_workspace['gid']
            else
              current
            end
          end
        end

        def clear
          Abt::GitConfig.unset_local('abt.asana.projectGid')
          Abt::GitConfig.unset_local('abt.asana.taskGid')
        end

        def clear_global
          Abt::GitConfig.unset_global('abt.asana.workspaceGid')
          Abt::GitConfig.unset_global('abt.asana.accessToken')
        end

        def client
          Abt::AsanaClient.new(access_token: access_token)
        end

        private

        def prompt_workspace
          workspaces = client.get_paged('workspaces')
          if workspaces.empty?
            abort 'Your asana access token does not have access to any workspaces'
          end

          # TODO: Handle if there are multiple workspaces
          workspace = workspaces.first
          Abt::GitConfig.global('abt.asana.workspaceGid', workspace['gid'])
          workspace
        end

        def access_token
          Abt::GitConfig.prompt_global(
            'abt.asana.accessToken',
            'Please enter your personal asana access_token',
            'Create a personal access token here: https://app.asana.com/0/developer-console'
          )
        end
      end
    end
  end
end
