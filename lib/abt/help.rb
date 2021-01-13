# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/help/*.rb").sort.each do |file|
  require file
end

module Abt
  module Help
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
          }
        }
      end

      def providers
        provider_definitions
      end

      private

      def commandize(string)
        string = string.to_s
        string[0] = string[0].downcase
        string.gsub(/([A-Z])/, '-\1').downcase
      end

      def provider_definitions
        Abt::Providers.constants.sort.each_with_object({}) do |provider_name, definition|
          provider_class = Abt::Providers.const_get(provider_name)

          definition[commandize(provider_name)] = command_definitions(provider_class)
        end
      end

      def command_definitions(provider_class)
        provider_class.constants.sort.each_with_object({}) do |command_name, definition|
          command_class = provider_class.const_get(command_name)

          if command_class.respond_to?(:command) && command_class.respond_to?(:description)
            definition[command_class.command] = command_class.description
          end
        end
      end
    end
  end
end
