# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Stop
        attr_reader :cli

        def initialize(cli:, **)
          @cli = cli
        end

        def call
          abort 'No running time entry' if time_entry.nil?

          harvest.patch("time_entries/#{time_entry['id']}/stop")
          warn 'Harvest time entry stopped'
          print_time_entry
        rescue Abt::HttpError::HttpError => e
          warn e
          abort 'Unable to stop time entry'
        end

        private

        def print_time_entry
          cli.print_provider_command(
            'harvest',
            "#{project['id']}/#{task['id']}",
            "#{project['name']} > #{task['name']}"
          )
        end

        def project
          time_entry['project']
        end

        def task
          time_entry['task']
        end

        def time_entry
          @time_entry ||= begin
            harvest.get_paged(
              'time_entries',
              is_running: true,
              user_id: Abt::GitConfig.global('harvest.userId')
            ).first
          rescue Abt::HttpError::HttpError => e # rubocop:disable Layout/RescueEnsureAlignment
            warn e
            abort 'Unable to fetch running time entry'
          end
        end

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
