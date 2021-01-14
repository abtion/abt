# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/asana/*.rb").sort.each do |file|
  require file
end

module Abt
  module Providers
    class Asana
      class << self
        def command_names
          constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
        end

        def command_class(name)
          const_name = Helpers.command_to_const(name)
          const_get(const_name) if const_defined?(const_name)
        end

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
