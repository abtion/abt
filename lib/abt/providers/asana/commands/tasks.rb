# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Tasks < BaseCommand
          def self.command
            'tasks asana'
          end

          def self.description
            'List available tasks on project - useful for piping into grep etc.'
          end

          def call
            tasks.each do |task|
              print_task(project, task)
            end
          end

          private

          def project
            @project ||= begin
              api.get("projects/#{project_gid}")
            end
          end

          def tasks
            @tasks ||= api.get_paged('tasks', project: project['gid'], opt_fields: 'name')
          end
        end
      end
    end
  end
end
