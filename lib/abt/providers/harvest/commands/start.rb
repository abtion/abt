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
            'As track, but also lets the user override the current task and triggers `start` commands for other providers ' # rubocop:disable Layout/LineLength
          end

          def call
            start_output = call_start
            puts start_output

            use_arg_str(arg_str_from_start_output(start_output))

            maybe_override_current_task
          rescue Abt::HttpError::HttpError => e
            cli.warn e
            cli.abort 'Unable to start tracker'
          end

          private

          def arg_str_from_start_output(output)
            output = output.split(' # ').first
            output.split(':')[1]
          end

          def call_start
            output = StringIO.new
            Abt::Cli.new(argv: ['track', *cli.args], output: output).perform

            output_str = output.string.strip
            cli.abort 'No task provided' if output_str.empty?
            output_str
          end

          def maybe_override_current_task
            return if arg_str.nil?
            return if same_args_as_config?
            return unless config.local_available?
            return unless cli.prompt_boolean 'Set selected task as current?'

            output = StringIO.new
            Abt::Cli.new(argv: ['current', "harvest:#{project_id}/#{task_id}"],
                         output: output).perform
          end
        end
      end
    end
  end
end
