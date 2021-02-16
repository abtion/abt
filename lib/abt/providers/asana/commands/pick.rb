# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Pick < BaseCommand
          def self.usage
            'abt pick asana[:<project-gid>]'
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

            task = select_task

            print_task(project, task)

            return if flags[:"dry-run"]

            config.path = Path.from_ids(project_gid, task['gid'])
          end

          private

          def project
            @project ||= api.get("projects/#{project_gid}")
          end

          def select_task
            loop do
              section = cli.prompt.choice 'Which section?', sections
              warn 'Fetching tasks...'
              tasks = tasks_in_section(section)

              if tasks.length.zero?
                warn 'Section is empty'
                next
              end

              task = cli.prompt.choice 'Select a task', tasks, true
              return task if task
            end
          end

          def tasks_in_section(section)
            api.get_paged('tasks', section: section['gid'], opt_fields: 'name,permalink_url')
          end

          def sections
            @sections ||= begin
              warn 'Fetching sections...'
              api.get_paged("projects/#{project_gid}/sections", opt_fields: 'name')
                          rescue Abt::HttpError::HttpError
                            []
            end
          end
        end
      end
    end
  end
end
