# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Start < BaseCommand
        def self.command
          'start harvest[:<project-id>/<task-id>]'
        end

        def self.description
          'Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana`' # rubocop:disable Layout/LineLength
        end

        def call
          Current.new(arg_str: arg_str, cli: cli).call unless arg_str.nil?

          abort('No task selected') if task_id.nil?

          create_time_entry

          warn 'Tracker successfully started'
        rescue Abt::HttpError::HttpError => e
          warn e
          abort 'Unable to start tracker'
        end

        private

        def create_time_entry
          body = Oj.dump({
            project_id: Abt::GitConfig.local('abt.harvest.projectId'),
            task_id: Abt::GitConfig.local('abt.harvest.taskId'),
            user_id: Harvest.user_id,
            spent_date: Date.today.iso8601
          }.merge(external_link_data), mode: :json)
          Harvest.client.post('time_entries', body)
        end

        def external_link_data
          @external_link_data ||= begin
            arg_strs = cli.args.join(' ')
            lines = `#{$PROGRAM_NAME} harvest-time-entry-data #{arg_strs}`.split("\n")

            return {} if lines.empty?

            # TODO: Make user choose which reference to use by printing the urls
            if lines.length > 1
              abort 'Multiple providers had harvest reference data, only one is supported at a time'
            end

            Oj.load(lines.first)
          end
        end
      end
    end
  end
end
