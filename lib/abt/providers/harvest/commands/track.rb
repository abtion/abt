# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Track < BaseCommand # rubocop:disable Metrics/ClassLength
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
               "Track amount of hours, this will create a stopped entry."],
              ["-i", "--since HH:MM",
               "Start entry today at specified time. The computed duration will be deducted from the running entry if one exists."] # rubocop:disable Layout/LineLength
            ]
          end

          def perform
            abort("Flags --time and --since cannot be used together") if flags[:time] && flags[:since]

            require_task!

            maybe_adjust_previous_entry
            entry = create_entry!

            print_task(entry["project"], entry["task"])

            maybe_override_current_task
          rescue Abt::HttpError::HttpError => _e
            abort("Invalid task")
          end

          private

          def create_entry!
            result = api.post("time_entries", Oj.dump(entry_data, mode: :json))
            api.patch("time_entries/#{result['id']}/restart") if flags.key?(:since)
            result
          end

          def maybe_adjust_previous_entry
            return unless flags.key?(:since)
            return unless since_flag_duration # Ensure --since flag is valid before fetching data
            return unless previous_entry

            adjust_previous_entry
          end

          def adjust_previous_entry
            updated_hours = previous_entry["hours"] - since_flag_duration
            abort("Cannot adjust previous entry to a negative duration") if updated_hours <= 0

            api.patch("time_entries/#{previous_entry['id']}", Oj.dump({ hours: updated_hours }, mode: :json))

            subtracted_minutes = (since_flag_duration * 60).round
            warn("~#{subtracted_minutes} minute(s) subtracted from previous entry")
          end

          def entry_data
            body = entry_base_data

            maybe_add_external_link(body)
            maybe_add_comment(body)
            maybe_add_hours(body)

            body
          end

          def entry_base_data
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

          def external_link_data
            return @external_link_data if instance_variable_defined?(:@external_link_data)
            return @external_link_data = nil if link_data_lines.empty?

            if link_data_lines.length > 1
              abort("Got reference data from multiple scheme providers, only one is supported at a time")
            end

            @external_link_data = Oj.load(link_data_lines.first, symbol_keys: true)
          end

          def link_data_lines
            @link_data_lines ||= begin
              other_aris = cli.aris - [ari]
              other_aris.map do |other_ari|
                input = StringIO.new(other_ari.to_s)
                output = StringIO.new
                Abt::Cli.new(argv: ["harvest-time-entry-data"], output: output, input: input).perform
                output.string.chomp
              end.reject(&:empty?)
            end
          end

          def maybe_add_comment(body)
            body[:notes] = flags[:comment] if flags.key?(:comment)
            body[:notes] ||= cli.prompt.text("Fill in comment (optional)")
          end

          def maybe_add_hours(body)
            if flags[:time]
              body[:hours] = flags[:time]
            elsif flags[:since]
              body[:hours] = since_flag_duration
            end
          end

          def maybe_override_current_task
            return unless flags[:set]
            return if path == config.path
            return unless config.local_available?

            config.path = path
            warn("Current task updated")
          end

          def since_flag_duration
            @since_flag_duration ||= begin
              since_hours = HarvestHelpers.decimal_hours_from_string(flags[:since])
              now_hours = HarvestHelpers.decimal_hours_from_string(Time.now.strftime("%T"))

              abort("Specified \"since\" time (#{flags[:since]}) is in the future") if now_hours <= since_hours

              now_hours - since_hours
            end
          end

          def previous_entry
            @previous_entry ||= api.get_paged("time_entries", is_running: true, user_id: config.user_id).first
          end
        end
      end
    end
  end
end
