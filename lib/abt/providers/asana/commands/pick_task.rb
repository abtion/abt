# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class PickTask < BaseCommand
          def self.command
            'pick-task asana[:<project-gid>]'
          end

          def self.description
            'Pick task for current git repository'
          end

          def call
            cli.warn project['name']

            task = cli.prompt_choice 'Select a task', tasks

            config.project_gid = project_gid # We might have gotten the project ID as an argument
            config.task_gid = task['gid']

            print_task(project, task)
          end

          private

          def project
            @project ||= api.get("projects/#{project_gid}")
          end

          def tasks
            @tasks ||= begin
              section = cli.prompt_choice 'Which section?', sections
              cli.warn 'Fetching tasks...'
              api.get_paged('tasks', section: section['gid'], opt_fields: 'name')
            end
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
