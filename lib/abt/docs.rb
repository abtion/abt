# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/docs/*.rb").sort.each do |file|
  require file
end

module Abt
  module Docs
    class << self
      def basic_examples
        {
          'Getting started:' => {
            'abt init asana harvest' => 'Setup asana and harvest project git repo in working dir',
            'abt pick harvest' => 'Pick harvest tasks, for most projects this will stay the same',
            'abt pick asana | abt start harvest' => 'Pick asana task and start working',
            'abt stop harvest' => 'Stop time tracker',
            'abt start asana harvest' => 'Continue working, e.g. after a break',
            'abt finalize asana' => 'Finalize the selected asana task'
          }
        }
      end

      def extended_examples
        {
          'Tracking meetings (without changing the config):' => {
            'abt tasks asana | grep -i standup | abt track harvest' => 'Track on asana meeting task without changing any configuration',
            'abt tasks harvest | grep -i comment | abt track harvest' => 'Track on harvest "Comment"-task (will prompt for a comment)'
          },
          'Command output can be piped, e.g.:' => {
            'abt tasks asana | grep -i <name of task>' => nil,
            'abt tasks asana | grep -i <name of task> | abt start' => nil
          },
          'Sharing configuration:' => {
            'abt share asana harvest | tr "\n" " "' => 'Print current configuration',
            'abt share asana harvest | tr "\n" " " | pbcopy' => 'Copy configuration (mac only)',
            'abt start <shared configuration>' => 'Start a shared configuration'
          },
          'Flags:' => {
            'abt start harvest -c "comment"' => 'Command flags are added directly after provider URIs',
            'abt start harvest -c "comment" -- asana' => 'Use -- to mark the end of a flag list if it\'s to be followed by a provider URI',
            'abt pick harvest | abt start -c "comment"' => 'Flags placed directly after a command applies to piped in URIs'
          }
        }
      end

      def providers
        provider_definitions
      end

      private

      def provider_definitions
        Abt.provider_names.sort.each_with_object({}) do |name, definition|
          definition[name] = command_definitions(name)
        end
      end

      def command_definitions(module_name)
        provider_module = Abt.provider_module(module_name)
        provider_module.command_names.each_with_object({}) do |name, definition|
          command_class = provider_module.command_class(name)
          full_name = "abt #{name} #{module_name}"

          if command_class.respond_to?(:usage) && command_class.respond_to?(:description)
            definition[full_name] = [command_class.usage, command_class.description]
          end
        end
      end
    end
  end
end
