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

        def path
          local_available? ? Path.from_ids(git['projectId'], git['taskId']) : Path.new
        end

        def path=(new_path)
          return if path == new_path

          clear_local(verbose: false)

          git['projectId'] = new_path.project_id
          git['taskId'] = new_path.task_id
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
          @api ||= Api.new(access_token: access_token, account_id: account_id)
        end
      end
    end
  end
end
