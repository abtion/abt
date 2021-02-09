# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Pick < BaseCommand
          def self.usage
            'abt pick harvest[:<project-id>]'
          end

          def self.description
            'Pick task for current git repository'
          end

          def perform
            cli.abort 'Must be run inside a git repository' unless config.local_available?
            require_project!

            cli.warn project['name']
            task = cli.prompt.choice 'Select a task', tasks

            config.project_id = project_id # We might have gotten the project ID as an argument
            config.task_id = task['id']

            print_task(project, task)
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
