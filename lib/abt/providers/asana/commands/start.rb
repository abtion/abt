# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Start < BaseCommand
          def self.command
            'start asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Set current task and move it to a section (column) of your choice'
          end

          def call
            override_current_task unless arg_str.nil?

            update_assignee_if_needed
            move_if_needed
          end

          private

          def override_current_task
            Current.new(arg_str: arg_str, cli: cli).call
          end

          def update_assignee_if_needed
            if task.dig('assignee', 'gid') == current_user['gid']
              cli.warn 'You are already assigned to this task'
            else
              cli.warn "Assigning task to #{current_user['name']}"
              update_assignee
            end
          end

          def move_if_needed
            if task_already_in_wip_section?
              cli.warn "Task already in #{current_task_section['name']}"
            else
              cli.warn "Moving task to #{wip_section['name']}"
              move_task
            end
          end

          def task_already_in_wip_section?
            !task_section_membership.nil?
          end

          def current_task_section
            task_section_membership&.dig('section')
          end

          def task_section_membership
            task['memberships'].find do |membership|
              membership.dig('section', 'gid') == config.wip_section_gid
            end
          end

          def wip_section
            @wip_section ||= api.get("sections/#{config.wip_section_gid}")
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{config.wip_section_gid}/addTask", body_json)
          end

          def update_assignee
            body = { data: { assignee: current_user['gid'] } }
            body_json = Oj.dump(body, mode: :json)
            api.put("tasks/#{task_gid}", body_json)
          end

          def current_user
            @current_user ||= api.get('users/me', opt_fields: 'name')
          end

          def task
            @task ||= api.get("tasks/#{task_gid}", opt_fields: 'memberships.section.name,assignee')
          end
        end
      end
    end
  end
end
