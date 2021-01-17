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
            abort 'No current/provided task' if task_gid.nil?

            maybe_override_current_task

            update_assignee_if_needed
            move_if_needed
          end

          private

          def maybe_override_current_task
            return if arg_str.nil?
            return if same_args_as_config?
            return unless config.local_available?

            should_override = cli.prompt_boolean 'Set selected task as current?'
            Current.new(arg_str: arg_str, cli: cli).call if should_override
          end

          def update_assignee_if_needed
            current_assignee = task.dig('assignee')

            if current_assignee.nil?
              cli.warn "Assigning task to user: #{current_user['name']}"
              update_assignee
            elsif current_assignee['gid'] == current_user['gid']
              cli.warn 'You are already assigned to this task'
            elsif cli.prompt_boolean "Task is assigned to: #{current_assignee['name']}, take over?"
              cli.warn "Reassigning task to user: #{current_user['name']}"
              update_assignee
            end
          end

          def move_if_needed
            unless project_gid == config.project_gid
              cli.warn 'Task was not moved, this is not implemented for tasks outside current project'
              return
            end

            if task_already_in_wip_section?
              cli.warn "Task already in section: #{current_task_section['name']}"
            else
              cli.warn "Moving task to section: #{wip_section['name']}"
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
            @task ||= api.get("tasks/#{task_gid}", opt_fields: 'name,memberships.section.name,assignee.name')
          end
        end
      end
    end
  end
end
