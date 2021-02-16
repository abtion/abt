# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class BaseCommand < Abt::Cli::BaseCommand
        extend Forwardable

        attr_reader :config, :path

        def_delegators(:@path, :project_id, :task_id)

        def initialize(ari:, cli:)
          super

          @config = Configuration.new(cli: cli)
          @path = ari.path ? Path.new(ari.path) : config.path
        end

        private

        def require_project!
          return if project_id

          abort 'No current/specified project. Did you initialize Harvest?'
        end

        def require_task!
          unless project_id
            abort 'No current/specified project. Did you initialize Harvest and pick a task?'
          end

          abort 'No current/specified task. Did you pick a Harvest task?' if task_id.nil?
        end

        def print_project(project)
          cli.print_ari(
            'harvest',
            project['id'],
            "#{project['client']['name']} > #{project['name']}"
          )
        end

        def print_task(project, task)
          cli.print_ari(
            'harvest',
            "#{project['id']}/#{task['id']}",
            "#{project['name']} > #{task['name']}"
          )
        end

        def api
          @api ||= Abt::Providers::Harvest::Api.new(access_token: config.access_token,
                                                    account_id: config.account_id)
        end
      end
    end
  end
end
