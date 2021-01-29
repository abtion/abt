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

        def organization_name
          local_available? ? git['organizationName'] : nil
        end

        def project_name
          local_available? ? git['projectName'] : nil
        end

        def board_id
          local_available? ? git['boardId'] : nil
        end

        def work_item_id
          local_available? ? git['workItemId'] : nil
        end

        def organization_name=(value)
          return if organization_name == value

          clear_local
          git['organizationName'] = value unless value.nil?
        end

        def project_name=(value)
          return if project_name == value

          git['projectName'] = value unless value.nil?
          git['boardId'] = nil
          git['workItemId'] = nil
        end

        def board_id=(value)
          return if board_id == value

          git['boardId'] = value unless value.nil?
          git['workItemId'] = nil
        end

        def work_item_id=(value)
          git['workItemId'] = value
        end

        def clear_local
          cli.abort 'No local configuration was found' unless local_available?

          git['organizationName'] = nil
          git['projectName'] = nil
          git['boardId'] = nil
          git['workItemId'] = nil
        end

        def username_for_organization(organization_name)
          username_key = "organizations.#{organization_name}.username"

          return git.global[username_key] unless git.global[username_key].nil?

          git.global[username_key] = cli.prompt([
            "Please provide your username for the DevOps organization (#{organization_name}).",
            '',
            'Enter username'
          ].join("\n"))
        end

        def access_token_for_organization(organization_name)
          access_token_key = "organizations.#{organization_name}.accessToken"

          return git.global[access_token_key] unless git.global[access_token_key].nil?

          git.global[access_token_key] = cli.prompt([
            "Please provide your personal access token for the DevOps organization (#{organization_name}).",
            'If you don\'t have one, follow the guide here: https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate',
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
