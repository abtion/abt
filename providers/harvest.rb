# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class BaseCommand
        attr_reader :arg_str, :project_id, :task_id, :cli

        def initialize(arg_str:, cli:)
          @arg_str = arg_str

          if arg_str.nil?
            use_current_args
          else
            use_arg_str(arg_str)
          end
          @cli = cli
        end

        private

        def use_current_args
          @project_id = Abt::GitConfig.local('abt.harvest.projectId').to_s
          @project_id = nil if project_id.empty?
          @task_id = Abt::GitConfig.local('abt.harvest.taskId').to_s
          @task_id = nil if task_id.empty?
        end

        def use_arg_str(arg_str)
          args = arg_str.to_s.split('/')
          @project_id = args[0].to_s
          @project_id = nil if project_id.empty?

          return if project_id.nil?

          @task_id = args[1].to_s
          @task_id = nil if @task_id.empty?
        end

        def remember_project_id(project_id)
          Abt::GitConfig.local('abt.harvest.projectId', project_id)
        end

        def remember_task_id(task_id)
          if task_id.nil?
            Abt::GitConfig.unset_local('abt.harvest.taskId')
          else
            Abt::GitConfig.local('abt.harvest.taskId', task_id)
          end
        end
      end

      class << self
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
