# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/docs/*.rb").sort.each do |file|
  require file
end

module Abt
  module Docs
    class << self
      def basic_examples
        {
          "Getting started:" => {
            "abt pick harvest" => "Pick harvest task. This will likely stay the same throughout the project",
            "abt pick asana | abt start harvest" => "Pick asana task and start tracking time",
            "abt stop harvest" => "Stop time tracker",
            "abt start asana harvest" => "Continue working, e.g., after a break",
            "abt finalize asana" => "Finalize the selected asana task"
          }
        }
      end

      def extended_examples # rubocop:disable Metrics/MethodLength
        {
          "Tracking meetings (without switching current task setting):" => {
            "abt pick asana -d | abt track harvest" => "Track on asana meeting task",
            'abt pick harvest -d | abt track harvest -c "Name of meeting"' => "Track on separate harvest-task"
          },
          "Many commands output ARIs that can be piped into other commands:" => {
            "abt tasks asana | grep -i <name of task>" => nil,
            "abt tasks asana | grep -i <name of task> | abt start" => nil
          },
          "Sharing ARIs:" => {
            'abt share asana harvest | tr "\n" " "' => "Print current asana and harvest ARIs on a single line",
            'abt share asana harvest | tr "\n" " " | pbcopy' => "Copy ARIs to clipboard (mac only)",
            "abt start <ARIs from coworker>" => "Work on a task your coworker shared with you",
            "abt current <ARIs from coworker> | abt start" => "Set task as current, then start it"
          },
          "Flags:" => {
            'abt start harvest -c "comment"' => "Add command flags after ARIs",
            'abt start harvest -c "comment" -- asana' =>
              "Use -- to end a list of flags, so that it can be followed by another ARI",
            'abt pick harvest | abt start -c "comment"' =>
              "Flags placed directly after a command applies to the piped in ARI"
          }
        }
      end

      def providers
        @providers ||= begin
          providers = {}

          providers["Global"] = global_command_definitions

          Abt.schemes.sort.each_with_object(providers) do |scheme, definition|
            definition[scheme] = command_definitions(scheme)
          end

          providers
        end
      end

      private

      def global_command_definitions
        global_command_names = Abt::Cli::GlobalCommands.command_names
        global_command_names.each_with_object({}) do |name, definition|
          command_class = Abt::Cli::GlobalCommands.command_class(name)
          full_name = "abt #{name}"

          if command_class.respond_to?(:usage) && command_class.respond_to?(:description)
            definition[full_name] = [command_class.usage.strip, command_class.description.strip]
          end
        end
      end

      def command_definitions(scheme)
        provider = Abt.scheme_provider(scheme)
        provider.command_names.each_with_object({}) do |name, definition|
          command_class = provider.command_class(name)
          full_name = "abt #{name} #{scheme}"

          if command_class.respond_to?(:usage) && command_class.respond_to?(:description)
            definition[full_name] = [command_class.usage.strip, command_class.description.strip]
          end
        end
      end
    end
  end
end
