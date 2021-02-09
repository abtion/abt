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

          def perform
            cli.abort 'Must be run inside a git repository' unless config.local_available?
            require_project!

            cli.warn project['name']

            task = select_task

            config.project_gid = project_gid # We might have gotten the project ID as an argument
            config.task_gid = task['gid']

            print_task(project, task)
          end

          private

          def project
            @project ||= api.get("projects/#{project_gid}")
          end

          def select_task
            loop do
              section = cli.prompt.choice 'Which section?', sections
              cli.warn 'Fetching tasks...'
              tasks = tasks_in_section(section)

              if tasks.length.zero?
                cli.warn 'Section is empty'
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
              cli.warn 'Fetching sections...'
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
