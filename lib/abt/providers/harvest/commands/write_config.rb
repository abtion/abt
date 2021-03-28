# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class WriteConfig < BaseCommand
          def self.usage
            "abt write-config harvest[:<project-id>[/<task-id>]]"
          end

          def self.description
            "Write Harvest settings to .abt.yml"
          end

          def self.flags
            [
              ["-c", "--clean", "Don't reuse configuration"]
            ]
          end

          def perform
            prompt_project! if project_id.nil? || flags[:clean]
            prompt_task! if task_id.nil? || flags[:clean]

            update_directory_config!

            warn("Harvest configuration written to #{Abt::DirectoryConfig::FILE_NAME}")
          end

          private

          def update_directory_config!
            cli.directory_config["harvest"] = { "path" => path.to_s }
            cli.directory_config.save!
          end
        end
      end
    end
  end
end
