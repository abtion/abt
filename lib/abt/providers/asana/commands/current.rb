# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Current < BaseCommand
          def self.usage
            "abt current asana[:<project-gid>[/<task-gid>]]"
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
            task_gid.nil? ? print_project(project) : print_task(project, task)
          end

          def ensure_valid_configuration!
            abort("Invalid project: #{project_gid}") if project.nil?
            abort("Invalid task: #{task_gid}") if task_gid && task.nil?
          end
        end
      end
    end
  end
end
