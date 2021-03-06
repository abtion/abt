# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class WriteConfig < BaseCommand
          def self.usage
            "abt write-config devops[:<organization-name>/<project-name>/<board-id>]"
          end

          def self.description
            "Write DevOps settings to .abt.yml"
          end

          def self.flags
            [
              ["-c", "--clean", "Don't reuse configuration"]
            ]
          end

          def perform
            prompt_board! if board_name.nil? || flags[:clean]

            update_directory_config!

            warn("DevOps configuration written to #{Abt::DirectoryConfig::FILE_NAME}")
          end

          private

          def update_directory_config!
            cli.directory_config["devops"] = {
              "path" => Path.from_ids(
                organization_name: organization_name,
                project_name: project_name,
                team_name: team_name,
                board_name: board_name
              ).to_s
            }
            cli.directory_config.save!
          end
        end
      end
    end
  end
end
