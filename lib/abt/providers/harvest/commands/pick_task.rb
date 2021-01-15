# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class PickTask < BaseCommand
          def self.command
            'pick-task harvest[:<project-id>]'
          end

          def self.description
            'Pick task for current git repository'
          end

          def call
            cli.warn project['name']
            task = cli.prompt_choice 'Select a task', tasks

            config.project_id = project_id # We might have gotten the project ID as an argument
            config.task_id = task['id']

            print_task(project, task)
          end

          private

          def project
            @project ||= api.get("projects/#{project_id}")
          end

          def tasks
            project_task_assignments.map { |assignment| assignment['task'] }
          end

          def project_task_assignments
            @project_task_assignments ||= begin
              api.get_paged("projects/#{project_id}/task_assignments", is_active: true)
            rescue Abt::HttpError::HttpError # rubocop:disable Layout/RescueEnsureAlignment
              []
            end
          end
        end
      end
    end
  end
end
