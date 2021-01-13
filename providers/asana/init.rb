# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Init < BaseCommand
        def call
          warn 'Loading projects'
          projects

          project = loop do
            matches = matches_for_string cli.prompt('Enter search')
            if matches.empty?
              warn 'No matches'
              next
            end

            warn 'Showing the 10 first matches' if matches.size > 10
            choice = cli.prompt_choice 'Select a project', matches[0...10], true
            break choice unless choice.nil?
          end

          remember_project_gid(project['gid'])
          remember_task_gid(nil)

          cli.print_provider_command('asana', project['gid'], project['name'])
        end

        private

        def matches_for_string(string)
          search_string = sanitize_string(string)

          projects.select do |project|
            sanitize_string(project['name']).include?(search_string)
          end
        end

        def sanitize_string(string)
          string.downcase.gsub(/[^\w]/, '')
        end

        def projects
          @projects ||= Asana.client.get_paged('projects', workspace: Asana.workspace_gid, archived: false)
        end
      end
    end
  end
end
