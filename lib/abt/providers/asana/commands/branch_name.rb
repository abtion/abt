# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class BranchName < BaseCommand
          def self.usage
            "abt branch-name asana[:<project-gid>/<task-gid>]"
          end

          def self.description
            "Suggest a git branch name for the current/specified task."
          end

          def perform
            require_task!
            ensure_current_is_valid!

            puts name
          end

          private

          def name
            task["name"].downcase.gsub(/[^\w]+/, "-").gsub(/(^-|-$)/, "")
          end

          def ensure_current_is_valid!
            abort("Invalid task gid: #{task_gid}") if task.nil?
          end
        end
      end
    end
  end
end
