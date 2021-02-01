# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Add < BaseCommand
          def self.command
            'start asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Set current task and move it to a section (column) of your choice'
          end

          def call
            abort 'No project' if project_gid.nil?

            task
            print_task(project, task)

            move_task if section
          end

          private

          def task
            @task ||= begin
              body = {
                data: {
                  name: name,
                  notes: notes,
                  projects: [project_gid]
                }
              }
              cli.warn 'Creating task'
              api.post('tasks', Oj.dump(body, mode: :json))
            end
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{section['gid']}/addTask", body_json)
          end

          def name
            @name ||= cli.prompt 'Enter task description'
          end

          def notes
            @notes ||= cli.prompt 'Enter task notes'
          end

          def project
            @project ||= api.get("projects/#{project_gid}")
          end

          def section
            @section ||= cli.prompt_choice 'Add to section?', sections, ['q', 'Don\'t add to section']
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
