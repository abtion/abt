# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Projects < BaseCommand
          def self.usage
            'abt projects asana'
          end

          def self.description
            'List all available projects - useful for piping into grep etc.'
          end

          def perform
            projects.map do |project|
              print_project(project)
            end
          end

          private

          def projects
            @projects ||= begin
              warn 'Fetching projects...'
              api.get_paged(
                'projects',
                workspace: config.workspace_gid,
                archived: false,
                opt_fields: 'name'
              )
            end
          end
        end
      end
    end
  end
end
