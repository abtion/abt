# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class BaseCommand < Abt::BaseCommand
        extend Forwardable

        attr_reader :config, :path

        def_delegators(:@path, :project_id, :task_id)

        def initialize(ari:, cli:)
          super

          @config = Configuration.new(cli: cli)
          @path = ari.path ? Path.new(ari.path) : config.path
        end

        private

        def require_local_config!
          abort("Must be run inside a git repository") unless config.local_available?
        end

        def require_project!
          return if project_id

          abort("No current/specified project. Did you forget to run `pick`?")
        end

        def require_task!
          require_project!
          return if task_id

          abort("No current/specified task. Did you forget to run `pick`?")
        end

        def prompt_project!
          result = Services::ProjectPicker.call(cli: cli, project_assignments: project_assignments)
          @path = result.path
          @project = result.project
        end

        def prompt_task!
          result = Services::TaskPicker.call(cli: cli, path: path, project_assignment: project_assignment)
          @path = result.path
          @task = result.task
        end

        def task
          return @task if instance_variable_defined?(:@task)

          @task = if project_assignment
                    project_assignment["task_assignments"].map { |ta| ta["task"] }.find do |task|
                      task["id"].to_s == task_id
                    end
                  end
        end

        def project
          return @project if instance_variable_defined?(:@project)

          @project = if project_assignment
                       project_assignment["project"].merge("client" => project_assignment["client"])
                     end
        end

        def project_assignment
          @project_assignment ||= project_assignments.find { |pa| pa["project"]["id"].to_s == path.project_id }
        end

        def project_assignments
          @project_assignments ||= begin
            warn("Fetching Harvest data...")
            api.get_paged("users/me/project_assignments")
          end
        end

        def print_project(project)
          cli.print_ari(
            "harvest",
            project["id"],
            "#{project['client']['name']} > #{project['name']}"
          )
        end

        def print_task(project, task)
          cli.print_ari(
            "harvest",
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
