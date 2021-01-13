# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Tasks < BaseCommand
        def self.command
          'tasks asana'
        end

        def self.description
          'List available tasks on project - E.g. for grepping and selecting `| grep -i <name> | abt current`' # rubocop:disable Metrics/LineLength
        end

        def call
          tasks.each do |task|
            print_task(project, task)
          end
        end

        private

        def project
          @project ||= begin
            Asana.client.get("projects/#{project_gid}")
          end
        end

        def tasks
          @tasks ||= Asana.client.get_paged('tasks', project: project['gid'])
        end
      end
    end
  end
end
