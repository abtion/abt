# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Start < BaseCommand
          def self.usage
            "abt start asana[:<project-gid>/<task-gid>]"
          end

          def self.description
            "Move current or specified task to WIP section (column) and assign it to you"
          end

          def self.flags
            [
              ["-s", "--set", "Set specified task as current"]
            ]
          end

          def perform
            require_task!

            print_task(project_gid, task)

            update_assignee_if_needed
            move_if_needed
            maybe_override_current_task
          end

          private

          def maybe_override_current_task
            return unless flags[:set]
            return if path.nil?
            return if path == config.path
            return unless config.local_available?

            config.path = path
            warn("Current task updated")
          end

          def update_assignee_if_needed
            if current_assignee.nil?
              warn("Assigning task to user: #{current_user['name']}")
              update_assignee
            elsif current_assignee["gid"] == current_user["gid"]
              warn("You are already assigned to this task")
            elsif should_reassign?
              warn("Reassigning task to user: #{current_user['name']}")
              update_assignee
            end
          end

          def current_assignee
            task["assignee"]
          end

          def should_reassign?
            cli.prompt.boolean("Task is assigned to: #{current_assignee['name']}, take over?")
          end

          def move_if_needed
            unless project_gid == config.path.project_gid
              warn("Task was not moved, this is not implemented for tasks outside current project")
              return
            end

            if task_already_in_wip_section?
              warn("Task already in section: #{current_task_section['name']}")
            else
              warn("Moving task to section: #{wip_section['name']}")
              move_task
            end
          end

          def task_already_in_wip_section?
            !task_section_membership.nil?
          end

          def current_task_section
            task_section_membership&.dig("section")
          end

          def task_section_membership
            task["memberships"].find do |membership|
              membership.dig("section", "gid") == config.wip_section_gid
            end
          end

          def wip_section
            @wip_section ||= api.get("sections/#{config.wip_section_gid}", opt_fields: "name")
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{config.wip_section_gid}/addTask", body_json)
          end

          def update_assignee
            body = { data: { assignee: current_user["gid"] } }
            body_json = Oj.dump(body, mode: :json)
            api.put("tasks/#{task_gid}", body_json)
          end

          def current_user
            @current_user ||= api.get("users/me", opt_fields: "name")
          end

          def task
            @task ||= api.get("tasks/#{task_gid}",
                              opt_fields: "name,memberships.section.name,assignee.name,permalink_url")
          end
        end
      end
    end
  end
end
