# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Init < BaseCommand
          def self.usage
            "abt init asana"
          end

          def self.description
            "Pick Asana project for current git repository"
          end

          def perform
            abort("Must be run inside a git repository") unless config.local_available?

            projects # Load projects up front to make it obvious that searches are instant
            project = cli.prompt.search("Select a project", projects)

            config.path = Path.from_ids(project["gid"])

            print_project(project)
          end

          private

          def projects
            @projects ||= begin
              warn("Fetching projects...")
              api.get_paged("projects",
                            workspace: config.workspace_gid,
                            archived: false,
                            opt_fields: "name,permalink_url")
            end
          end
        end
      end
    end
  end
end
