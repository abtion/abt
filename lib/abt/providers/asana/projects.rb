# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Projects < BaseCommand
        def self.command
          'projects asana'
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
          @projects ||=
            Asana.client.get_paged('projects', workspace: Asana.workspace_gid, archived: false)
        end
      end
    end
  end
end
