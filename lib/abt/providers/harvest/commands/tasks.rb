# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      module Commands
        class Tasks < BaseCommand
          def self.command
            'tasks harvest'
          end

          def self.description
            'List available tasks on project - useful for piping into grep etc.'
          end

          def call
            project_task_assignments.each do |a|
              project = a['project']
              task = a['task']

              print_task(project, task)
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
end
