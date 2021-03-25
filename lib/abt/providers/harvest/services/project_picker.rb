# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Services
        class ProjectPicker
          class Result
            attr_reader :project, :path

            def initialize(project:, path:)
              @project = project
              @path = path
            end
          end

          def self.call(**args)
            new(**args).call
          end

          attr_reader :cli, :project_assignments

          def initialize(cli:, project_assignments:)
            @cli = cli
            @project_assignments = project_assignments
          end

          def call
            project = cli.prompt.search("Select a project", searchable_projects)["project"]

            path = Path.from_ids(project_id: project["id"])

            Result.new(project: project, path: path)
          end

          private

          def searchable_projects
            @searchable_projects ||= project_assignments.map do |project_assignment|
              client = project_assignment["client"]
              project = project_assignment["project"]

              project_assignment.merge(
                "name" => "#{client['name']} > #{project['name']}",
                "project" => project
              )
            end
          end
        end
      end
    end
  end
end
