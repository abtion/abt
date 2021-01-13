# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Projects < BaseCommand
        def self.command
          'projects harvest'
        end

        def self.description
          'List all available projects - useful for piping into grep etc.'
        end

        def call
          projects.map do |project|
            print_project(project)
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
