# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
        end

        def local_available?
          git.available?
        end

        def path
          Path.new(local_available? && git["path"] || cli.directory_config.dig("devops", "path") || "")
        end

        def path=(new_path)
          git["path"] = new_path
        end

        def clear_local(verbose: true)
          git.clear(output: verbose ? cli.err_output : nil)
        end

        def clear_global(verbose: true)
          git_global.clear(output: verbose ? cli.err_output : nil)
        end

        def username_for_organization(organization_name)
          username_key = "organizations.#{organization_name}.username"

          return git_global[username_key] unless git_global[username_key].nil?

          git_global[username_key] = cli.prompt.text([
            "Please provide your username for the DevOps organization (#{organization_name}).",
            "",
            "Enter username"
          ].join("\n"))
        end

        def access_token_for_organization(organization_name)
          access_token_key = "organizations.#{organization_name}.accessToken"

          return git_global[access_token_key] unless git_global[access_token_key].nil?

          git_global[access_token_key] = cli.prompt.text(<<~TXT)
            Please provide your personal access token for the DevOps organization (#{organization_name}).
            If you don't have one, follow the guide here: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate

            The token MUST have "Read" permission for Work Items
            Future features will likely require "Write" or "Manage

            Enter access token"
          TXT
        end

        private

        def git
          @git ||= GitConfig.new("local", "abt.devops")
        end

        def git_global
          @git_global ||= GitConfig.new("global", "abt.devops")
        end
      end
    end
  end
end
