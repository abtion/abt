# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class BranchName < BaseCommand
          def self.command
            'branch-name asana[:<project-gid>/<task-gid>]'
          end

          def self.description
            'Suggest a git branch name for the current/specified task.'
          end

          def perform
            require_task!
            ensure_current_is_valid!

            cli.puts name
          end

          private

          def name
            task['name'].downcase.gsub(/[^\w]+/, '-')
          end

          def ensure_current_is_valid!
            cli.abort "Invalid task gid: #{task_gid}" if task.nil?

            return if task['memberships'].any? { |m| m.dig('project', 'gid') == project_gid }

            cli.abort "Invalid project gid: #{project_gid}"
          end

          def task
            @task ||= api.get("tasks/#{task_gid}", opt_fields: 'name,memberships.project')
          end
        end
      end
    end
  end
end
