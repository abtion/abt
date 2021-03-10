# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Init < BaseCommand
          AZURE_DEV_URL_REGEX = %r{^https://dev\.azure\.com/(?<organization>[^/]+)/(?<project>[^/]+)}.freeze
          VS_URL_REGEX = %r{^https://(?<organization>[^.]+)\.visualstudio\.com/(?<project>[^/]+)}.freeze

          def self.usage
            "abt init devops"
          end

          def self.description
            "Pick DevOps board for current git repository"
          end

          def perform
            abort("Must be run inside a git repository") unless config.local_available?

            board = cli.prompt.choice("Select a project work board", boards)

            config.path = Path.from_ids(organization_name, project_name, board["id"])
            print_board(organization_name, project_name, board)
          end

          private

          def boards
            @boards ||= api.get_paged("work/boards")
          end

          def project_name
            @project_name ||= begin
              if (match = AZURE_DEV_URL_REGEX.match(project_url)) ||
                 (match = VS_URL_REGEX.match(project_url))
                match[:project]
              end
            end
          end

          def organization_name
            @organization_name ||= begin
              if (match = AZURE_DEV_URL_REGEX.match(project_url)) ||
                 (match = VS_URL_REGEX.match(project_url))
                match[:organization]
              end
            end
          end

          def project_url
            @project_url ||= begin
              loop do
                url = cli.prompt.text([
                  "Please provide the URL for the devops project",
                  "For instance https://{organization}.visualstudio.com/{project} or https://dev.azure.com/{organization}/{project}",
                  "",
                  "Enter URL"
                ].join("\n"))

                break url if AZURE_DEV_URL_REGEX =~ url || VS_URL_REGEX =~ url

                warn("Invalid URL")
              end
            end
          end
        end
      end
    end
  end
end
