# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Pick < BaseCommand
          def self.usage
            "abt pick asana[:<project-gid>]"
          end

          def self.description
            "Pick a task and - unless told not to - make it current"
          end

          def self.flags
            [
              ["-d", "--dry-run", "Keep existing configuration"],
              ["-c", "--clean", "Don't reuse project configuration"]
            ]
          end

          def perform
            pick!

            print_task(project, task)

            return if flags[:"dry-run"]

            if config.local_available?
              config.path = Path.from_gids(project_gid: project["gid"], task_gid: task["gid"])
            else
              warn("No local configuration to update - will function as dry run")
            end
          end

          private

          def pick!
            prompt_project! if project_gid.nil? || flags[:clean]
            prompt_task!
          end
        end
      end
    end
  end
end
