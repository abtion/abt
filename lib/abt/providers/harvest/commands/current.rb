# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Current < BaseCommand
          def self.usage
            "abt current harvest[:<project-id>[/<task-id>]]"
          end

          def self.description
            "Get or set project and or task for current git repository"
          end

          def perform
            require_local_config!
            require_project!
            ensure_valid_configuration!

            if path != config.path
              config.path = path
              warn("Configuration updated")
            end

            print_configuration
          end

          private

          def print_configuration
            if task_id.nil?
              print_project(project)
            else
              print_task(project, task)
            end
          end

          def ensure_valid_configuration!
            abort("Invalid project: #{project_id}") if project.nil?
            abort("Invalid task: #{task_id}") if task_id && task.nil?
          end
        end
      end
    end
  end
end
