# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Move < BaseCommand
        def self.command
          'move asana[:<project-gid>/<task-gid>]'
        end

        def self.description
          'Move current or specified task to another section (column)'
        end

        def call
          cli.print_provider_command('asana', "#{project_gid}/#{task['gid']}", task['name'])

          move_task

          warn "Asana task moved to #{section['name']}"
        rescue Abt::HttpError::HttpError => e
          warn e
          abort 'Unable to move asana task'
        end

        private

        def task
          @task ||= Asana.client.get("tasks/#{task_gid}")
        end

        def move_task
          body = { data: { task: task_gid } }
          body_json = Oj.dump(body, mode: :json)
          Asana.client.post("sections/#{section['gid']}/addTask", body_json)
        end

        def section
          @section ||= cli.prompt_choice 'Move asana task to?', sections
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
