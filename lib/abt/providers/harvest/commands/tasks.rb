# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Tasks < BaseCommand
          def self.usage
            "abt tasks harvest"
          end

          def self.description
            "List available tasks on project - useful for piping into grep etc."
          end

          def perform
            prompt_project! unless project_id

            tasks.each do |task|
              print_task(project, task)
            end
          end

          private

          def tasks
            @tasks ||= project_assignment["task_assignments"].map { |ta| ta["task"] }
          end
        end
      end
    end
  end
end
