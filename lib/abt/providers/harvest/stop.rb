# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Stop < BaseCommand
        def self.command
          'stop harvest'
        end

        def self.description
          'Stop running harvest tracker'
        end

        def call
          abort 'No running time entry' if time_entry.nil?

          Harvest.client.patch("time_entries/#{time_entry['id']}/stop")
          warn 'Harvest time entry stopped'
          print_task(project, task)
        rescue Abt::HttpError::HttpError => e
          warn e
          abort 'Unable to stop time entry'
        end

        private

        def project
          time_entry['project']
        end

        def task
          time_entry['task']
        end

        def time_entry
          @time_entry ||= begin
            Harvest.client.get_paged(
              'time_entries',
              is_running: true,
              user_id: Harvest.user_id
            ).first
          rescue Abt::HttpError::HttpError => e # rubocop:disable Layout/RescueEnsureAlignment
            warn e
            abort 'Unable to fetch running time entry'
          end
        end
      end
    end
  end
end
