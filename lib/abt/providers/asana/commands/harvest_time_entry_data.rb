# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class HarvestTimeEntryData < BaseCommand
          def self.command
            'harvest-time-entry-data asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Print Harvest time entry data for Asana task as json. Used by harvest start script.'
          end

          def call
            ensure_current_is_valid!

            body = {
              notes: task['name'],
              external_reference: {
                id: task_gid.to_i,
                group_id: project_gid.to_i,
                permalink: task['permalink_url']
              }
            }

            cli.puts Oj.dump(body, mode: :json)
          end

          private

          def ensure_current_is_valid!
            cli.abort "Invalid task gid: #{task_gid}" if task.nil?

            return if task['memberships'].any? { |m| m.dig('project', 'gid') == project_gid }

            cli.abort "Invalid project gid: #{project_gid}"
          end

          def task
            @task ||= api.get("tasks/#{task_gid}", opt_fields: 'name,permalink_url,memberships.project')
          end
        end
      end
    end
  end
end
