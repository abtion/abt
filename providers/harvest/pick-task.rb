# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class PickTask < BaseCommand
        def call
          warn project['name']
          task = cli.prompt_choice 'Select a task', tasks

          remember_project_id(project_id) # We might have gotten the project ID as an argument
          remember_task_id(task['id'])

          cli.print_provider_command('harvest', "#{project['id']}/#{task['id']}", "#{project['name']} > #{task['name']}")
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
