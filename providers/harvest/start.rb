# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Start
        attr_reader :arg_str, :cli

        def initialize(arg_str:, cli:)
          @arg_str = arg_str
          @cli = cli
        end

        def call
          Current.new(arg_str: arg_str, cli: cli).call

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
            user_id: Abt::GitConfig.global('harvest.userId'),
            spent_date: Date.today.iso8601
          }.merge(external_link_data), mode: :json)
          harvest.post('time_entries', body)
        end

        def external_link_data
          @external_link_data ||= begin
            arg_strs = cli.args.join(' ')
            lines = `#{$PROGRAM_NAME} harvest-link-time-entry-data #{arg_strs}`.split("\n")

            return {} if lines.empty?

            # TODO: Make user choose which reference to use by printing the urls
            if lines.length > 1
              abort 'Multiple providers had harvest reference data, only one is supported at a time'
            end

            Oj.load(lines.first)
          end
        end

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
