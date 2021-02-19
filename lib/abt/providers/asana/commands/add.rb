# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Add < BaseCommand
          def self.usage
            'abt add asana[:<project-gid>]'
          end

          def self.description
            'Create a new task for the current/specified Asana project'
          end

          def perform
            require_project!

            task

            warn 'Task created'
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
              api.post('tasks', Oj.dump(body, mode: :json))
            end
          end

          def move_task
            body = { data: { task: task['gid'] } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{section['gid']}/addTask", body_json)
          end

          def name
            @name ||= cli.prompt.text 'Enter task description'
          end

          def notes
            @notes ||= cli.prompt.text 'Enter task notes'
          end

          def project
            @project ||= api.get("projects/#{project_gid}", opt_fields: 'name')
          end

          def section
            @section ||= cli.prompt.choice 'Add to section?', sections, ['q', 'Don\'t add to section']
          end

          def sections
            @sections ||= begin
              warn 'Fetching sections...'
              api.get_paged("projects/#{project_gid}/sections", opt_fields: 'name')
            end
          end
        end
      end
    end
  end
end
