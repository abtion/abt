# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/harvest/*.rb").sort.each { |file| require file }
Dir.glob("#{File.expand_path(__dir__)}/harvest/commands/*.rb").sort.each { |file| require file }

module Abt
  module Providers
    class Harvest
      class << self
        def command_names
          Commands.constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
        end

        def command_class(name)
          const_name = Helpers.command_to_const(name)
          Commands.const_get(const_name) if Commands.const_defined?(const_name)
        end

        def user_id
          Abt::GitConfig.prompt_global(
            'abt.harvest.userId',
            'Please enter your harvest User ID',
            'In harvest open "My profile". The ID is the number part of the URL you are taken to'
          )
        end

        def access_token
          Abt::GitConfig.prompt_global(
            'abt.harvest.accessToken',
            'Please enter your personal harvest access token',
            'Create your personal access token here: https://id.getharvest.com/developers'
          )
        end

        def account_id
          Abt::GitConfig.prompt_global(
            'abt.harvest.accountId',
            'Please enter the harvest account id',
            'This information is shown next to your generated access token'
          )
        end

        def clear
          Abt::GitConfig.unset_local('abt.harvest.projectId')
          Abt::GitConfig.unset_local('abt.harvest.taskId')
        end

        def clear_global
          Abt::GitConfig.unset_global('abt.harvest.userId')
          Abt::GitConfig.unset_global('abt.harvest.accountId')
          Abt::GitConfig.unset_global('abt.harvest.accessToken')
        end

        def client
          @client ||= Abt::HarvestClient.new(access_token: access_token, account_id: account_id)
        end
      end
    end
  end
end
