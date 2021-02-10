# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
          @git = GitConfig.new(namespace: 'abt.asana')
        end

        def local_available?
          GitConfig.local_available?
        end

        def project_gid
          local_available? ? git['projectGid'] : nil
        end

        def task_gid
          local_available? ? git['taskGid'] : nil
        end

        def workspace_gid
          @workspace_gid ||= begin
            current = git.global['workspaceGid']
            if current.nil?
              prompt_workspace['gid']
            else
              current
            end
          end
        end

        def wip_section_gid
          return nil unless local_available?

          @wip_section_gid ||= git['wipSectionGid'] || prompt_wip_section['gid']
        end

        def finalized_section_gid
          return nil unless local_available?

          @finalized_section_gid ||= git['finalizedSectionGid'] || prompt_finalized_section['gid']
        end

        def project_gid=(value)
          return if project_gid == value

          clear_local(verbose: false)
          git['projectGid'] = value unless value.nil?
        end

        def task_gid=(value)
          git['taskGid'] = value
        end

        def clear_local(verbose: true)
          git.clear(output: verbose ? cli.err_output : nil)
        end

        def clear_global(verbose: true)
          git.global.clear(output: verbose ? cli.err_output : nil)
        end

        def access_token
          return git.global['accessToken'] unless git.global['accessToken'].nil?

          git.global['accessToken'] = cli.prompt.text([
            'Please provide your personal access token for Asana.',
            'If you don\'t have one, create one here: https://app.asana.com/0/developer-console',
            '',
            'Enter access token'
          ].join("\n"))
        end

        private

        attr_reader :git

        def prompt_finalized_section
          section = prompt_section('Select section for finalized tasks (E.g. "Merged")')
          git['finalizedSectionGid'] = section['gid']
          section
        end

        def prompt_wip_section
          section = prompt_section('Select WIP (Work In Progress) section')
          git['wipSectionGid'] = section['gid']
          section
        end

        def prompt_section(message)
          cli.warn 'Fetching sections...'
          sections = api.get_paged("projects/#{project_gid}/sections")
          cli.prompt.choice(message, sections)
        end

        def prompt_workspace
          cli.warn 'Fetching workspaces...'
          workspaces = api.get_paged('workspaces')
          if workspaces.empty?
            cli.abort 'Your asana access token does not have access to any workspaces'
          elsif workspaces.one?
            workspace = workspaces.first
            cli.warn "Selected Asana workspace #{workspace['name']}"
          else
            workspace = cli.prompt.choice('Select Asana workspace', workspaces)
          end

          git.global['workspaceGid'] = workspace['gid']
          workspace
        end

        def api
          Abt::Providers::Asana::Api.new(access_token: access_token)
        end
      end
    end
  end
end
