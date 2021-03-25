# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Services
        class ProjectPicker
          class Result
            attr_reader :board, :path

            def initialize(path:)
              @path = path
            end
          end

          AZURE_DEV_URL_REGEX = %r{^https://dev\.azure\.com/(?<organization>[^/]+)/(?<project>[^/]+)}.freeze
          VS_URL_REGEX = %r{^https://(?<organization>[^.]+)\.visualstudio\.com/(?<project>[^/]+)}.freeze

          extend Forwardable

          def self.call(**args)
            new(**args).call
          end

          attr_reader :cli

          def initialize(cli:)
            @cli = cli
          end

          def call
            Result.new(
              path: Path.from_ids(organization_name: organization_name, project_name: project_name)
            )
          end

          private

          def project_name
            @project_name ||= begin
              project_url_match && project_url_match[:project]
            end
          end

          def organization_name
            @organization_name ||= begin
              project_url_match && project_url_match[:organization]
            end
          end

          def project_url_match
            AZURE_DEV_URL_REGEX.match(project_url) || VS_URL_REGEX.match(project_url)
          end

          def project_url
            @project_url ||= begin
              loop do
                url = prompt_url

                break url if AZURE_DEV_URL_REGEX =~ url || VS_URL_REGEX =~ url

                cli.warn("Invalid URL")
              end
            end
          end

          def prompt_url
            cli.prompt.text(<<~TXT)
              Please provide the URL for the devops project
              For instance https://{organization}.visualstudio.com/{project} or https://dev.azure.com/{organization}/{project}

              Enter URL
            TXT
          end
        end
      end
    end
  end
end
