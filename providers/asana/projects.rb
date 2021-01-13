# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Projects < BaseCommand
        def call
          projects.map do |project|
            cli.print_provider_command('asana', project['gid'], project['name'])
          end
        end

        private

        def projects
          @projects ||= Asana.client.get_paged('projects', workspace: Asana.workspace_gid, archived: false)
        end
      end
    end
  end
end
