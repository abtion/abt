# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Tasks < BaseCommand
          def self.command
            'tasks harvest'
          end

          def self.description
            'List available tasks on project - useful for piping into grep etc.'
          end

          def call
            require_project!

            tasks.each do |task|
              print_task(project, task)
            end
          end

          private

          def project
            project_assignment['project']
          end

          def tasks
            @tasks ||= project_assignment['task_assignments'].map { |ta| ta['task'] }
          end

          def project_assignment
            @project_assignment ||= begin
              project_assignments.find { |pa| pa['project']['id'].to_s == project_id }
            end
          end

          def project_assignments
            @project_assignments ||= api.get_paged('users/me/project_assignments')
          end
        end
      end
    end
  end
end
