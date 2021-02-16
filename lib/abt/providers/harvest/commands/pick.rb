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

          def self.flags
            [
              ['-d', '--dry-run', 'Keep existing configuration']
            ]
          end

          def perform
            abort 'Must be run inside a git repository' unless config.local_available?
            require_project!

            warn project['name']
            task = cli.prompt.choice 'Select a task', tasks

            print_task(project, task)

            return if flags[:"dry-run"]

            config.path = Path.from_ids(project_id, task['id'])
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
