# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Start < BaseCommand
          def self.command
            'start harvest[:<project-id>/<task-id>]'
          end

          def self.description
            'Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana`' # rubocop:disable Layout/LineLength
          end

          def call
            abort 'No current/provided task' if task_id.nil?

            maybe_override_current_task

            print_task(project, task)

            cli.abort('No task selected') if task_id.nil?

            create_time_entry

            cli.warn 'Tracker successfully started'
          rescue Abt::HttpError::HttpError => e
            cli.warn e
            cli.abort 'Unable to start tracker'
          end

          private

          def maybe_override_current_task
            return if arg_str.nil?
            return if same_args_as_config?
            return unless config.local_available?

            should_override = cli.prompt_boolean 'Set selected task as current?'
            Current.new(arg_str: arg_str, cli: cli).call if should_override
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

          def project
            project_assignment['project']
          end

          def task
            @task ||= project_assignment['task_assignments'].map { |ta| ta['task'] }.find do |task|
              task['id'].to_s == task_id
            end
          end

          def project_assignment
            @project_assignment ||= begin
              project_assignments.find { |pa| pa['project']['id'].to_s == project_id }
            end
          end

          def project_assignments
            @project_assignments ||= api.get_paged('users/me/project_assignments')
          end

          def external_link_data
            @external_link_data ||= begin
              arg_strs = cli.args.join(' ')
              lines = `#{$PROGRAM_NAME} harvest-time-entry-data #{arg_strs}`.split("\n")

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
