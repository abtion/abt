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
            Current.new(arg_str: arg_str, cli: cli).call unless arg_str.nil?

            if task_already_in_wip_section?
              cli.warn "Task already in #{current_task_section['name']}"
            else
              cli.warn "Moving task to #{wip_section['name']}"
              move_task
            end
          end

          private

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

          def task
            @task ||= api.get("tasks/#{task_gid}")
          end
        end
      end
    end
  end
end
