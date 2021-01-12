# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Tasks < BaseCommand
        def call
          project_task_assignments.each do |a|
            project = a['project']
            task = a['task']

            cli.print_provider_command(
              'harvest',
              "#{project['id']}/#{task['id']}",
              "#{project['name']} > #{task['name']}"
            )
          end
        end

        private

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
