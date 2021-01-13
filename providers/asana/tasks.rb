# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Tasks < BaseCommand
        def call
          tasks.each do |task|
            cli.print_provider_command('asana', "#{project['gid']}/#{task['gid']}", task['name'])
          end
        end

        private

        def project
          @project ||= begin
            Asana.client.get("projects/#{project_gid}")
          end
        end

        def tasks
          @tasks ||= asana.get_paged('tasks', project: project['gid'])
        end
      end
    end
  end
end
