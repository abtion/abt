# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Track < BaseCommand
          def self.command
            'track harvest[:<project-id>/<task-id>]'
          end

          def self.description
            'Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana`' # rubocop:disable Layout/LineLength
          end

          def call
            abort 'No current/provided task' if task_id.nil?
            cli.abort('No task selected') if task_id.nil?

            print_task(created_time_entry['project'], created_time_entry['task'])

            cli.warn 'Tracker successfully started'
          rescue Abt::HttpError::HttpError => e
            cli.abort 'Invalid task'
          end

          private

          def created_time_entry
            @created_time_entry ||= create_time_entry
          end

          def create_time_entry
            body = {
              project_id: project_id,
              task_id: task_id,
              user_id: config.user_id,
              spent_date: Date.today.iso8601
            }

            if external_link_data
              body.merge! external_link_data
            else
              cli.warn 'No external link provided'
              body[:notes] ||= cli.prompt('Fill in comment (optional)')
            end

            api.post('time_entries', Oj.dump(body, mode: :json))
          end

          def external_link_data
            @external_link_data ||= begin
              input = StringIO.new(cli.args.join(' '))
              output = StringIO.new
              Abt::Cli.new(argv: ['harvest-time-entry-data'], output: output, input: input).perform

              lines = output.string.strip.lines

              return if lines.empty?

              # TODO: Make user choose which reference to use by printing the urls
              if lines.length > 1
                cli.abort('Multiple providers had harvest reference data, only one is supported at a time') # rubocop:disable Layout/LineLength
              end

              Oj.load(lines.first)
            end
          end
        end
      end
    end
  end
end
