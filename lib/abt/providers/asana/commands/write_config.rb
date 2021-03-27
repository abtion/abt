# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class WriteConfig < BaseCommand
          def self.usage
            "abt write-config asana[:<project-gid>]"
          end

          def self.description
            "Write Asana settings to .abt.yml"
          end

          def self.flags
            [
              ["-c", "--clean", "Don't reuse project configuration"]
            ]
          end

          def perform
            cli.directory_config["asana"] = config_data
            cli.directory_config.save!

            warn("Asana configuration written to #{Abt::DirectoryConfig::FILE_NAME}")
          end

          private

          def config_data
            {
              "path" => project_gid,
              "wip_section_gid" => wip_section_gid,
              "finalized_section_gid" => finalized_section_gid
            }
          end

          def project_gid
            @project_gid ||= begin
              prompt_project! if super.nil? || flags[:clean]

              super
            end
          end

          def wip_section_gid
            return config.wip_section_gid if use_previous_config?

            cli.prompt.choice("Select WIP (Work In Progress) section", sections)["gid"]
          end

          def finalized_section_gid
            return config.finalized_section_gid if use_previous_config?

            cli.prompt.choice('Select section for finalized tasks (E.g. "Merged")', sections)["gid"]
          end

          def use_previous_config?
            project_gid == config.path.project_gid
          end

          def sections
            @sections ||= begin
              warn("Fetching sections...")
              api.get_paged("projects/#{project_gid}/sections", opt_fields: "name")
            end
          end
        end
      end
    end
  end
end
