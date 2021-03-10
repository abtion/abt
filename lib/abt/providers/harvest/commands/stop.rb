# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Stop < BaseCommand
          def self.usage
            "abt stop harvest"
          end

          def self.description
            "Stop running harvest tracker"
          end

          def perform
            abort("No running time entry") if time_entry.nil?

            stop_time_entry

            warn("Harvest time entry stopped")
            print_task(project, task)
          end

          private

          def stop_time_entry
            api.patch("time_entries/#{time_entry['id']}/stop")
          rescue Abt::HttpError::HttpError => e
            warn(e)
            abort("Unable to stop time entry")
          end

          def project
            time_entry["project"]
          end

          def task
            time_entry["task"]
          end

          def time_entry
            @time_entry ||= begin
              api.get_paged(
                "time_entries",
                is_running: true,
                user_id: config.user_id
              ).first
            rescue Abt::HttpError::HttpError => e
              warn(e)
              abort("Unable to fetch running time entry")
            end
          end
        end
      end
    end
  end
end
