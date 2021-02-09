# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Projects < BaseCommand
          def self.command
            'projects harvest'
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
              cli.warn 'Fetching projects...'
              project_assignments.map do |project_assignment|
                project_assignment['project'].merge('client' => project_assignment['client'])
              end
            end
          end

          def project_assignments
            @project_assignments ||= api.get_paged('users/me/project_assignments')
          end
        end
      end
    end
  end
end
