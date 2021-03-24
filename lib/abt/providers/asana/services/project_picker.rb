# frozen_string_literal: true

module Abt
  module Providers
    module Asana
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

          attr_reader :cli, :config

          def initialize(cli:, config:)
            @cli = cli
            @config = config
          end

          def call
            project = cli.prompt.search("Select a project", projects)
            path = Path.from_gids(project_gid: project["gid"])

            Result.new(project: project, path: path)
          end

          private

          def projects
            @projects ||= begin
              cli.warn("Fetching projects...")
              api.get_paged("projects",
                            workspace: config.workspace_gid,
                            archived: false,
                            opt_fields: "name,permalink_url")
            end
          end

          def api
            Abt::Providers::Asana::Api.new(access_token: config.access_token)
          end
        end
      end
    end
  end
end
