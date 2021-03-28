# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Pick < BaseCommand
          def self.usage
            "abt pick harvest[:<project-id>]"
          end

          def self.description
            "Pick task for current git repository"
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

            unless config.local_available?
              warn("No local configuration to update - will function as dry run")
              return
            end

            config.path = path
          end

          private

          def pick!
            prompt_project! if project_id.nil? || flags[:clean]
            prompt_task!
          end
        end
      end
    end
  end
end
