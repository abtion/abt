# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Init < BaseCommand
          AZURE_DEV_URL_REGEX = %r{^https://dev\.azure\.com/(?<organization>[^/]+)/(?<project>[^/]+)}.freeze
          VS_URL_REGEX = %r{^https://(?<organization>[^.]+)\.visualstudio\.com/(?<project>[^/]+)}.freeze

          def self.command
            'init devops'
          end

          def self.description
            'Pick Devops board for current git repository'
          end

          def call
            cli.abort 'Must be run inside a git repository' unless config.local_available?

            @organization_name = config.organization_name = organization_name_from_url
            @project_name = config.project_name = project_name_from_url

            board = cli.prompt_choice 'Select a project work board', boards

            config.board_id = board['id']

            print_board(organization_name, project_name, board)
          end

          private

          def boards
            @boards ||= api.get_paged('work/boards')
          end

          def project_name_from_url
            if (match = AZURE_DEV_URL_REGEX.match(project_url)) ||
               (match = VS_URL_REGEX.match(project_url))
              match[:project]
            end
          end

          def organization_name_from_url
            if (match = AZURE_DEV_URL_REGEX.match(project_url)) ||
               (match = VS_URL_REGEX.match(project_url))
              match[:organization]
            end
          end

          def project_url
            @project_url ||= begin
              loop do
                url = cli.prompt([
                  'Please provide the URL for the devops project',
                  'For instance https://{organization}.visualstudio.com/{project} or https://dev.azure.com/{organization}/{project}',
                  '',
                  'Enter URL'
                ].join("\n"))

                break url if AZURE_DEV_URL_REGEX =~ url || VS_URL_REGEX =~ url

                cli.warn 'Invalid URL'
              end
            end
          end
        end
      end
    end
  end
end
