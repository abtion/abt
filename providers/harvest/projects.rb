# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Projects < BaseCommand
        def self.command
          'projects harvest'
        end

        def self.description
          'List all available projects - E.g. for grepping and selecting `| grep -i <name> | abt current`'
        end

        def call
          projects.map do |p|
            cli.print_provider_command('harvest', p['id'], "#{p['client']['name']} > #{p['name']}")
          end
        end

        private

        def projects
          @projects ||= Harvest.client.get_paged('projects', is_active: true)
        end
      end
    end
  end
end
