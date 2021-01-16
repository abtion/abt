# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/docs/*.rb").sort.each do |file|
  require file
end

module Abt
  module Docs
    class << self
      def examples # rubocop:disable Metrics/MethodLength
        {
          'Multiple providers and arguments can be passed, e.g.:' => {
            'abt init asana harvest' => nil,
            'abt pick-task asana harvest' => nil,
            'abt start asana harvest' => nil,
            'abt clear asana harvest' => nil
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

          if command_class.respond_to?(:command) && command_class.respond_to?(:description)
            definition[command_class.command] = command_class.description
          end
        end
      end
    end
  end
end
