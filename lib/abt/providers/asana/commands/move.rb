# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Move < BaseCommand
          def self.command
            'move asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Move current or specified task to another section (column)'
          end

          def call
            print_task(project, task)

            move_task

            cli.warn "Asana task moved to #{section['name']}"
          rescue Abt::HttpError::HttpError => e
            cli.warn e
            cli.abort 'Unable to move asana task'
          end

          private

          def task
            @task ||= api.get("tasks/#{task_gid}")
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{section['gid']}/addTask", body_json)
          end

          def section
            @section ||= cli.prompt_choice 'Move asana task to?', sections
          end

          def project
            @project ||= api.get("projects/#{project_gid}", opt_fields: 'name')
          end

          def sections
            api.get_paged("projects/#{project_gid}/sections", opt_fields: 'name')
          rescue Abt::HttpError::HttpError
            []
          end
        end
      end
    end
  end
end
