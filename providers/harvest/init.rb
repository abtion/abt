# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
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

          remember_project_id(project['id'])
          remember_task_id(nil)

          cli.print_provider_command('harvest', project['id'], project['name'])
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
          @projects ||= Harvest.client.get_paged('projects')
        end
      end
    end
  end
end
