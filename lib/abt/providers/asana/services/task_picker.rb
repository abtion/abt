# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Services
        class TaskPicker
          class Result
            attr_reader :task, :path

            def initialize(task:, path:)
              @task = task
              @path = path
            end
          end

          def self.call(**args)
            new(**args).call
          end

          attr_reader :cli, :path, :config, :project

          def initialize(cli:, path:, config:, project:)
            @cli = cli
            @path = path
            @config = config
            @project = project
          end

          def call
            task = select_task

            path_with_task = Path.from_gids(project_gid: path.project_gid, task_gid: task["gid"])

            Result.new(task: task, path: path_with_task)
          end

          private

          def select_task
            section = prompt_section
            tasks = tasks_in_section(section)

            if tasks.length.zero?
              cli.warn("Section is empty")
              select_task
            else
              cli.prompt.choice("Select a task", options_for_tasks(tasks), nil_option: true) || select_task
            end
          end

          def prompt_section
            cli.prompt.choice("Which section in #{project['name']}?", sections)
          end

          def options_for_tasks(tasks)
            tasks.map do |task|
              formatted_name = [
                task["name"],
                formatted_assignee(task)
              ].compact.join(" ")

              task.merge("name" => formatted_name)
            end
          end

          def formatted_assignee(task)
            name = task.dig("assignee", "name")

            return unless name

            initials = name.split.map(&:chr).join.upcase
            "(#{initials}👤)"
          end

          def tasks_in_section(section)
            cli.warn("Fetching tasks...")
            tasks = api.get_paged(
              "tasks",
              section: section["gid"],
              opt_fields: "name,completed,permalink_url,assignee.name"
            )

            # The below filtering is the best we can do with Asanas api, see this:
            # https://forum.asana.com/t/tasks-query-completed-since-is-broken-for-sections/21461
            tasks.reject { |task| task["completed"] }
          end

          def sections
            @sections ||= begin
              cli.warn("Fetching sections...")
              api.get_paged("projects/#{project['gid']}/sections", opt_fields: "name")
            end
          end

          def api
            Abt::Providers::Asana::Api.new(access_token: config.access_token)
          end
        end
      end
    end
  end
end
