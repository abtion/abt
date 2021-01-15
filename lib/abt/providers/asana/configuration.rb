# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
        end

        def project_gid
          Abt::GitConfig.local('abt.asana.projectGid')
        end

        def task_gid
          Abt::GitConfig.local('abt.asana.taskGid')
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

        def wip_section_gid
          @wip_section_gid ||= begin
            current = Abt::GitConfig.local('abt.asana.wipSectionGid')
            if current.nil?
              prompt_wip_section['gid']
            else
              current
            end
          end
        end

        def finalized_section_gid
          @finalized_section_gid ||= begin
            current = Abt::GitConfig.local('abt.asana.finalizedSectionGid')
            if current.nil?
              prompt_finalized_section['gid']
            else
              current
            end
          end
        end

        def project_gid=(value)
          return if project_gid == value

          clear_local
          Abt::GitConfig.local('abt.asana.projectGid', value) unless value.nil?
        end

        def task_gid=(value)
          if value.nil?
            Abt::GitConfig.unset_local('abt.asana.taskGid')
          elsif task_gid != value
            Abt::GitConfig.local('abt.asana.taskGid', value)
          end
        end

        def clear_local
          Abt::GitConfig.unset_local('abt.asana.projectGid')
          Abt::GitConfig.unset_local('abt.asana.taskGid')
          Abt::GitConfig.unset_local('abt.asana.wipSectionGid')
          Abt::GitConfig.unset_local('abt.asana.finalizedSectionGid')
        end

        def clear_global
          Abt::GitConfig.unset_global('abt.asana.workspaceGid')
          Abt::GitConfig.unset_global('abt.asana.accessToken')
        end

        def access_token
          Abt::GitConfig.prompt_global(
            'abt.asana.accessToken',
            'Please enter your personal asana access_token',
            'Create a personal access token here: https://app.asana.com/0/developer-console'
          )
        end

        private

        def prompt_finalized_section
          section = prompt_section('Select section for finalized tasks (E.g. "Merged")')
          Abt::GitConfig.local('abt.asana.finalizedSectionGid', section['gid'])
          section
        end

        def prompt_wip_section
          section = prompt_section('Select WIP (Work In Progress) section')
          Abt::GitConfig.local('abt.asana.wipSectionGid', section['gid'])
          section
        end

        def prompt_section(message)
          sections = api.get_paged("projects/#{project_gid}/sections")
          cli.prompt_choice(message, sections)
        end

        def prompt_workspace
          workspaces = api.get_paged('workspaces')
          if workspaces.empty?
            cli.abort 'Your asana access token does not have access to any workspaces'
          end

          # TODO: Handle if there are multiple workspaces
          workspace = workspaces.first
          Abt::GitConfig.global('abt.asana.workspaceGid', workspace['gid'])
          workspace
        end

        def api
          Abt::Providers::Asana::Api.new(access_token: access_token)
        end
      end
    end
  end
end
