# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
          @git = GitConfig.new(namespace: 'abt.devops')
        end

        def local_available?
          GitConfig.local_available?
        end

        def path
          Path.new(local_available? && git['path'] || '')
        end

        def path=(new_path)
          git['path'] = new_path
        end

        def clear_local(verbose: true)
          git.clear(output: verbose ? cli.err_output : nil)
        end

        def clear_global(verbose: true)
          git.global.clear(output: verbose ? cli.err_output : nil)
        end

        def username_for_organization(organization_name)
          username_key = "organizations.#{organization_name}.username"

          return git.global[username_key] unless git.global[username_key].nil?

          git.global[username_key] = cli.prompt.text([
            "Please provide your username for the DevOps organization (#{organization_name}).",
            '',
            'Enter username'
          ].join("\n"))
        end

        def access_token_for_organization(organization_name)
          access_token_key = "organizations.#{organization_name}.accessToken"

          return git.global[access_token_key] unless git.global[access_token_key].nil?

          git.global[access_token_key] = cli.prompt.text([
            "Please provide your personal access token for the DevOps organization (#{organization_name}).",
            'If you don\'t have one, follow the guide here: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate',
            '',
            'The token MUST have "Read" permission for Work Items',
            'Future features will likely require "Write" or "Manage"',
            '',
            'Enter access token'
          ].join("\n"))
        end

        private

        attr_reader :git
      end
    end
  end
end
