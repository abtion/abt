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

          def initialize(cli:, **)
            @config = Configuration.new(cli: cli)
            @cli = cli
          end

          def perform
            abort("Must be run inside a git repository") unless config.local_available?

            projects # Load projects up front to make it obvious that searches are instant
            project = find_search_result

            config.path = Path.from_ids(project["gid"])

            print_project(project)
          end

          private

          def find_search_result
            warn("Select a project")

            loop do
              matches = matches_for_string(cli.prompt.text("Enter search"))
              if matches.empty?
                warn("No matches")
                next
              end

              warn("Showing the 10 first matches") if matches.size > 10
              choice = cli.prompt.choice("Select a project", matches[0...10], true)
              break choice unless choice.nil?
            end
          end

          def matches_for_string(string)
            search_string = sanitize_string(string)

            projects.select do |project|
              sanitize_string(project["name"]).include?(search_string)
            end
          end

          def sanitize_string(string)
            string.downcase.gsub(/[^\w]/, "")
          end

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
