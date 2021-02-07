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

        def local_available?
          GitConfig.local_available?
        end

        def project_id
          local_available? ? git['projectId'] : nil
        end

        def task_id
          local_available? ? git['taskId'] : nil
        end

        def project_id=(value)
          value = value.to_s unless value.nil?
          return if project_id == value

          clear_local
          git['projectId'] = value
        end

        def task_id=(value)
          value = value.to_s unless value.nil?
          git['taskId'] = value
        end

        def clear_local
          cli.abort 'No local configuration was found' unless local_available?

          git['projectId'] = nil
          git['taskId'] = nil
        end

        def clear_global
          git.global.keys.each do |key|
            cli.puts 'Deleting configuration: ' + key
            git.global[key] = nil
          end
        end

        def access_token
          return git.global['accessToken'] unless git.global['accessToken'].nil?

          git.global['accessToken'] = cli.prompt.text([
            'Please provide your personal access token for Harvest.',
            'If you don\'t have one, create one here: https://id.getharvest.com/developers',
            '',
            'Enter access token'
          ].join("\n"))
        end

        def account_id
          return git.global['accountId'] unless git.global['accountId'].nil?

          git.global['accountId'] = cli.prompt.text([
            'Please provide harvest account id.',
            'This information is shown next to your generated access token',
            '',
            'Enter account id'
          ].join("\n"))
        end

        def user_id
          return git.global['userId'] unless git.global['userId'].nil?

          git.global['userId'] = api.get('users/me')['id'].to_s
        end

        private

        attr_reader :git

        def api
          @api ||=
            Abt::Providers::Harvest::Api.new(access_token: access_token, account_id: account_id)
        end
      end
    end
  end
end
