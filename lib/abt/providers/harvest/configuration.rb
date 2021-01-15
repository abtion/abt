# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Configuration
        attr_accessor :cli

        def initialize(cli:)
          @cli = cli
        end

        def project_id
          Abt::GitConfig.local('abt.harvest.projectId')
        end

        def task_id
          Abt::GitConfig.local('abt.harvest.taskId')
        end

        def project_id=(value)
          return if project_id == value

          clear_local
          Abt::GitConfig.local('abt.harvest.projectId', value) unless value.nil?
        end

        def task_id=(value)
          if value.nil?
            Abt::GitConfig.unset_local('abt.harvest.taskId')
          elsif task_id != value
            Abt::GitConfig.local('abt.harvest.taskId', value)
          end
        end

        def clear_local
          Abt::GitConfig.unset_local('abt.harvest.projectId')
          Abt::GitConfig.unset_local('abt.harvest.taskId')
        end

        def clear_global
          Abt::GitConfig.unset_global('abt.harvest.userId')
          Abt::GitConfig.unset_global('abt.harvest.accountId')
          Abt::GitConfig.unset_global('abt.harvest.accessToken')
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

        def user_id
          Abt::GitConfig.prompt_global(
            'abt.harvest.userId',
            'Please enter your harvest User ID',
            'In harvest open "My profile". The ID is the number part of the URL you are taken to'
          )
        end
      end
    end
  end
end
