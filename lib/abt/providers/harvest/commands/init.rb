# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Init < BaseCommand
          def self.usage
            "abt init harvest"
          end

          def self.description
            "Pick Harvest project for current git repository"
          end

          def perform
            abort("Must be run inside a git repository") unless config.local_available?

            projects # Load projects up front to make it obvious that searches are instant
            project = cli.prompt.search("Select a project", searchable_projects)["project"]

            config.path = Path.from_ids(project["id"])

            print_project(project)
          end

          private

          def searchable_projects
            @searchable_projects ||= projects.map do |project|
              {
                "name" => "#{project['client']['name']} > #{project['name']}",
                "project" => project
              }
            end
          end

          def projects
            @projects ||= begin
              warn("Fetching projects...")
              project_assignments.map do |project_assignment|
                project_assignment["project"].merge("client" => project_assignment["client"])
              end
            end
          end

          def project_assignments
            @project_assignments ||= api.get_paged("users/me/project_assignments")
          end
        end
      end
    end
  end
end
