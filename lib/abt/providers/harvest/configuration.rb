# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
          @git = GitConfig.new('local', 'abt.harvest')
          @git_global = GitConfig.new('global', 'abt.harvest')
        end

        def local_available?
          git.available?
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
          git_global.clear(output: verbose ? cli.err_output : nil)
        end

        def access_token
          return git_global['accessToken'] unless git_global['accessToken'].nil?

          git_global['accessToken'] = cli.prompt.text([
            'Please provide your personal access token for Harvest.',
            'If you don\'t have one, create one here: https://id.getharvest.com/developers',
            '',
            'Enter access token'
          ].join("\n"))
        end

        def account_id
          return git_global['accountId'] unless git_global['accountId'].nil?

          git_global['accountId'] = cli.prompt.text([
            'Please provide harvest account id.',
            'This information is shown next to your generated access token',
            '',
            'Enter account id'
          ].join("\n"))
        end

        def user_id
          return git_global['userId'] unless git_global['userId'].nil?

          git_global['userId'] = api.get('users/me')['id'].to_s
        end

        private

        attr_reader :git, :git_global

        def api
          @api ||= Api.new(access_token: access_token, account_id: account_id)
        end
      end
    end
  end
end
