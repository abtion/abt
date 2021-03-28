# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
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

          attr_reader :cli, :path, :project_assignment

          def initialize(cli:, path:, project_assignment:)
            @cli = cli
            @path = path
            @project_assignment = project_assignment
          end

          def call
            task = cli.prompt.choice("Select a task from #{project['name']}", tasks)

            path_with_task = Path.from_ids(project_id: path.project_id, task_id: task["id"])

            Result.new(task: task, path: path_with_task)
          end

          private

          def project
            project_assignment["project"]
          end

          def tasks
            @tasks ||= project_assignment["task_assignments"].map { |ta| ta["task"] }
          end
        end
      end
    end
  end
end
