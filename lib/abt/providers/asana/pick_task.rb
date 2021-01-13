# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class PickTask < BaseCommand
        def self.command
          'pick-task asana[:<project-gid>]'
        end

        def self.description
          'Pick task for current git repository'
        end

        def call
          warn project['name']
          task = cli.prompt_choice 'Select a task', tasks

          remember_project_gid(project_gid) # We might have gotten the project ID as an argument
          remember_task_gid(task['gid'])

          print_task(project, task)
        end

        private

        def project
          @project ||= Asana.client.get("projects/#{project_gid}")
        end

        def tasks
          @tasks ||= begin
            section = cli.prompt_choice 'Which section?', sections
            Asana.client.get_paged('tasks', section: section['gid'])
          end
        end

        def sections
          Asana.client.get_paged("projects/#{project_gid}/sections")
        rescue Abt::HttpError::HttpError
          []
        end
      end
    end
  end
end