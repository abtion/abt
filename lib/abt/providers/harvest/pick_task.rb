# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
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

          remember_project_id(project_id) # We might have gotten the project ID as an argument
          remember_task_id(task['id'])

          print_task(project, task)
        end

        private

        def project
          @project ||= Harvest.client.get("projects/#{project_id}")
        end

        def tasks
          project_task_assignments.map { |assignment| assignment['task'] }
        end

        def project_task_assignments
          @project_task_assignments ||= begin
            Harvest.client.get_paged("projects/#{project_id}/task_assignments", is_active: true)
          rescue Abt::HttpError::HttpError # rubocop:disable Layout/RescueEnsureAlignment
            []
          end
        end
      end
    end
  end
end
