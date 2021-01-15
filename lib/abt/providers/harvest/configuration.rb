# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
          @git = GitConfig.new(namespace: 'abt.harvest')
        end

        def project_id
          git['projectId']
        end

        def task_id
          git['taskId']
        end

        def project_id=(value)
          return if project_id == value

          clear_local
          git['projectId'] = value unless value.nil?
        end

        def task_id=(value)
          git['taskId'] = value
        end

        def clear_local
          git['projectId'] = nil
          git['taskId'] = nil
        end

        def clear_global
          git.global['userId'] = nil
          git.global['accountId'] = nil
          git.global['accessToken'] = nil
        end

        def access_token
          return git.global['accessToken'] unless git.global['accessToken'].nil?

          git.global['accessToken'] = cli.prompt([
            'Please provide your personal access token for Harvest.',
            'If you don\'t have one, create one here: https://id.getharvest.com/developers',
            '',
            'Enter access token'
          ].join("\n"))
        end

        def account_id
          return git.global['accountId'] unless git.global['accountId'].nil?

          git.global['accountId'] = cli.prompt([
            'Please provide harvest account id.',
            'This information is shown next to your generated access token',
            '',
            'Enter account id'
          ].join("\n"))
        end

        def user_id
          return git.global['userId'] unless git.global['userId'].nil?

          git.global['userId'] = cli.prompt([
            'Please provide your harvest User ID.',
            'To find it open "My profile" inside the harvest web UI.',
            'The ID is the number part of the URL for that page.',
            '',
            'Enter user id'
          ].join("\n"))
        end

        private

        attr_reader :git
      end
    end
  end
end
