# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/docs/*.rb").sort.each do |file|
  require file
end

module Abt
  module Docs
    class << self
      def examples # rubocop:disable Metrics/MethodLength
        {
          'Getting started:' => {
            'abt init asana harvest' => 'Setup asana and harvest project git repo in working dir',
            'abt pick harvest' => 'Pick harvest tasks, for most projects this will stay the same',
            'abt pick asana | abt start harvest' => 'Pick asana task and start working',
            'abt stop harvest' => 'Stop time tracker',
            'abt start asana harvest' => 'Continue working, e.g. after a break',
            'abt finalize asana' => 'Finalize the selected asana task'
          },
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
          }
        }
      end

      def providers
        provider_definitions
      end

      private

      def provider_definitions
        Abt.provider_names.sort.each_with_object({}) do |name, definition|
          provider_module = Abt.provider_module(name)

          definition[name] = command_definitions(provider_module)
        end
      end

      def command_definitions(provider_module)
        provider_module.command_names.each_with_object({}) do |name, definition|
          command_class = provider_module.command_class(name)

          if command_class.respond_to?(:usage) && command_class.respond_to?(:description)
            definition[command_class.usage] = command_class.description
          end
        end
      end
    end
  end
end
