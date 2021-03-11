# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
        end

        def local_available?
          git.available?
        end

        def path
          Path.new(local_available? && git["path"] || "")
        end

        def path=(new_path)
          git["path"] = new_path
        end

        def workspace_gid
          @workspace_gid ||= begin
            current = git_global["workspaceGid"]
            if current.nil?
              prompt_workspace_gid
            else
              current
            end
          end
        end

        def wip_section_gid
          return nil unless local_available?

          @wip_section_gid ||= git["wipSectionGid"] || prompt_wip_section["gid"]
        end

        def finalized_section_gid
          return nil unless local_available?

          @finalized_section_gid ||= git["finalizedSectionGid"] || prompt_finalized_section["gid"]
        end

        def clear_local(verbose: true)
          git.clear(output: verbose ? cli.err_output : nil)
        end

        def clear_global(verbose: true)
          git_global.clear(output: verbose ? cli.err_output : nil)
        end

        def access_token
          return git_global["accessToken"] unless git_global["accessToken"].nil?

          git_global["accessToken"] = cli.prompt.text([
            "Please provide your personal access token for Asana.",
            "If you don't have one, create one here: https://app.asana.com/0/developer-console",
            "",
            "Enter access token"
          ].join("\n"))
        end

        private

        def git
          @git ||= GitConfig.new("local", "abt.asana")
        end

        def git_global
          @git_global ||= GitConfig.new("global", "abt.asana")
        end

        def prompt_finalized_section
          section = prompt_section('Select section for finalized tasks (E.g. "Merged")')
          git["finalizedSectionGid"] = section["gid"]
          section
        end

        def prompt_wip_section
          section = prompt_section("Select WIP (Work In Progress) section")
          git["wipSectionGid"] = section["gid"]
          section
        end

        def prompt_section(message)
          cli.warn("Fetching sections...")
          sections = api.get_paged("projects/#{path.project_gid}/sections", opt_fields: "name")
          cli.prompt.choice(message, sections)
        end

        def prompt_workspace_gid
          cli.abort("Your asana access token does not have access to any workspaces") if workspaces.empty?

          if workspaces.one?
            workspace = workspaces.first
            cli.warn("Selected Asana workspace: #{workspace['name']}")
          else
            workspace = pick_workspace
          end

          git_global["workspaceGid"] = workspace["gid"]
        end

        def pick_workspace
          cli.prompt.choice("Select Asana workspace", workspaces)
        end

        def workspaces
          @workspaces ||= begin
            cli.warn("Fetching workspaces...")
            api.get_paged("workspaces", opt_fields: "name")
          end
        end

        def api
          Abt::Providers::Asana::Api.new(access_token: access_token)
        end
      end
    end
  end
end
