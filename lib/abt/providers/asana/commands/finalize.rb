# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Finalize < BaseCommand
          def self.usage
            "abt finalize asana[:<project-gid>/<task-gid>]"
          end

          def self.description
            "Move current/specified task to section (column) for finalized tasks"
          end

          def perform
            abort("This is a no-op for tasks outside the current project") unless project_gid == config.path.project_gid
            require_task!
            print_task(project_gid, task)

            maybe_move_task
          end

          private

          def maybe_move_task
            if task_already_in_finalized_section?
              warn("Task already in section: #{current_task_section['name']}")
            else
              warn("Moving task to section: #{finalized_section['name']}")
              move_task
            end
          end

          def task_already_in_finalized_section?
            !task_section_membership.nil?
          end

          def current_task_section
            task_section_membership&.dig("section")
          end

          def task_section_membership
            task["memberships"].find do |membership|
              membership.dig("section", "gid") == config.finalized_section_gid
            end
          end

          def finalized_section
            @finalized_section ||= api.get("sections/#{config.finalized_section_gid}",
                                           opt_fields: "name")
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{config.finalized_section_gid}/addTask", body_json)
          end

          def task
            @task ||= begin
              api.get("tasks/#{task_gid}",
                      opt_fields: "name,memberships.section.name,permalink_url")
            end
          end
        end
      end
    end
  end
end
