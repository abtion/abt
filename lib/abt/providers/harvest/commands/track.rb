# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Track < BaseCommand
          def self.usage
            "abt track harvest[:<project-id>/<task-id>] [options]"
          end

          def self.description
            <<~TXT
              Start tracker for current or specified task. Add a relevant ARI to link the time entry, e.g. `abt track harvest asana`
            TXT
          end

          def self.flags
            [
              ["-s", "--set", "Set specified task as current"],
              ["-c", "--comment COMMENT", "Override comment"],
              ["-t", "--time HOURS",
               "Set hours. Creates a stopped entry unless used with --running"],
              ["-r", "--running", "Used with --time, starts the created time entry"]
            ]
          end

          def perform
            require_task!

            print_task(created_time_entry["project"], created_time_entry["task"])

            maybe_override_current_task
          rescue Abt::HttpError::HttpError => _e
            abort("Invalid task")
          end

          private

          def created_time_entry
            @created_time_entry ||= create_time_entry
          end

          def create_time_entry
            body = time_entry_data

            result = api.post("time_entries", Oj.dump(body, mode: :json))

            api.patch("time_entries/#{result['id']}/restart") if flags.key?(:time) && flags[:running]

            result
          end

          def time_entry_data
            body = time_entry_base_data

            maybe_add_external_link(body)
            maybe_add_comment(body)
            maybe_add_time(body)

            body
          end

          def time_entry_base_data
            {
              project_id: project_id,
              task_id: task_id,
              user_id: config.user_id,
              spent_date: Date.today.iso8601
            }
          end

          def maybe_add_external_link(body)
            if external_link_data
              warn(<<~TXT)
                Linking to:
                #{external_link_data[:notes]}
                #{external_link_data[:external_reference][:permalink]}
              TXT
              body.merge!(external_link_data)
            else
              warn("No external link provided")
            end
          end

          def maybe_add_comment(body)
            body[:notes] = flags[:comment] if flags.key?(:comment)
            body[:notes] ||= cli.prompt.text("Fill in comment (optional)")
          end

          def maybe_add_time(body)
            body[:hours] = flags[:time] if flags.key?(:time)
          end

          def external_link_data
            return @external_link_data if instance_variable_defined?(:@external_link_data)

            lines = fetch_link_data_lines

            return @external_link_data = nil if lines.empty?

            if lines.length > 1
              abort("Got reference data from multiple scheme providers, only one is supported at a time")
            end

            @external_link_data = Oj.load(lines.first, symbol_keys: true)
          end

          def fetch_link_data_lines
            other_aris = cli.aris - [ari]
            return [] if other_aris.empty?

            input = StringIO.new(other_aris.to_s)
            output = StringIO.new
            Abt::Cli.new(argv: ["harvest-time-entry-data"], output: output, input: input).perform

            output.string.strip.lines
          end

          def maybe_override_current_task
            return unless flags[:set]
            return if path == config.path
            return unless config.local_available?

            config.path = path
            warn("Current task updated")
          end
        end
      end
    end
  end
end
