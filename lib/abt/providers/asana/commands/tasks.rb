# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Tasks < BaseCommand
          def self.usage
            "abt tasks asana"
          end

          def self.description
            "List available tasks on project - useful for piping into grep etc."
          end

          def perform
            prompt_project! unless project_gid

            tasks.each do |task|
              print_task(project, task)
            end
          end

          private

          def tasks
            @tasks ||= begin
              project
              warn("Fetching tasks...")
              tasks = api.get_paged("tasks", project: project["gid"], opt_fields: "name,completed")
              tasks.reject { |task| task["completed"] }
            end
          end
        end
      end
    end
  end
end
