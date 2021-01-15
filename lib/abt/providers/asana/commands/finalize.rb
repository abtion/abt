# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Finalize < BaseCommand
          def self.command
            'finalize asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Move current/specified task to section (column) for finalized tasks'
          end

          def call
            cli.abort 'No current or specified task' if task.nil?

            if task_already_in_finalized_section?
              cli.warn "Task already in #{current_task_section['name']}"
            else
              cli.warn "Moving task to #{finalized_section['name']}"
              move_task
            end
          end

          private

          def task_already_in_finalized_section?
            !task_section_membership.nil?
          end

          def current_task_section
            task_section_membership&.dig('section')
          end

          def task_section_membership
            task['memberships'].find do |membership|
              membership.dig('section', 'gid') == config.finalized_section_gid
            end
          end

          def finalized_section
            @finalized_section ||= api.get("sections/#{config.finalized_section_gid}")
          end

          def move_task
            body = { data: { task: task_gid } }
            body_json = Oj.dump(body, mode: :json)
            api.post("sections/#{config.finalized_section_gid}/addTask", body_json)
          end

          def task
            @task ||= begin
              if task_gid.nil?
                nil
              else
                api.get("tasks/#{task_gid}")
              end
            end
          end
        end
      end
    end
  end
end