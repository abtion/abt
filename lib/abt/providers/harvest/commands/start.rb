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
            track_output = call_track
            puts track_output

            use_arg_str(arg_str_from_track_output(track_output))

            maybe_override_current_task
          rescue Abt::HttpError::HttpError => e
            cli.warn e
            cli.abort 'Unable to start tracker'
          end

          private

          def arg_str_from_track_output(output)
            output = output.split(' # ').first
            output.split(':')[1]
          end

          def call_track
            input = StringIO.new(cli.args.join(' '))
            output = StringIO.new
            Abt::Cli.new(argv: ['track'], output: output, input: input).perform

            output.string.strip
          end

          def maybe_override_current_task
            return if arg_str.nil?
            return if same_args_as_config?
            return unless config.local_available?
            return unless cli.prompt_boolean 'Set selected task as current?'

            input = StringIO.new("harvest:#{project_id}/#{task_id}")
            output = StringIO.new
            Abt::Cli.new(argv: ['current'], output: output, input: input).perform
          end
        end
      end
    end
  end
end
