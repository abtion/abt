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
            'abt pick asana -d | abt track harvest' => 'Track on asana meeting task',
            'abt pick harvest -d | abt track harvest -c "Name of meeting"' => 'Track on separate harvest-task'
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
            'abt start harvest -c "comment"' => 'Add command flags after <scheme>:<path>',
            'abt start harvest -c "comment" -- asana' => 'Use -- to mark the end of a flag list if it\'s to be followed by a <scheme-argument>',
            'abt pick harvest | abt start -c "comment"' => 'Flags placed directly after a command applies to piped in <scheme-argument>'
          }
        }
      end

      def providers
        @providers ||= Abt.schemes.sort.each_with_object({}) do |scheme, definition|
          definition[scheme] = command_definitions(scheme)
        end
      end

      private

      def command_definitions(scheme)
        provider = Abt.scheme_provider(scheme)
        provider.command_names.each_with_object({}) do |name, definition|
          command_class = provider.command_class(name)
          full_name = "abt #{name} #{scheme}"

          if command_class.respond_to?(:usage) && command_class.respond_to?(:description)
            definition[full_name] = [command_class.usage, command_class.description]
          end
        end
      end
    end
  end
end
