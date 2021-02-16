# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Current < BaseCommand
          def self.usage
            'abt current asana[:<project-gid>[/<task-gid>]]'
          end

          def self.description
            'Get or set project and or task for current git repository'
          end

          def perform
            require_project!

            if path != config.path && config.local_available?
              warn 'Updating configuration'
              update_configuration
            end

            print_configuration
          end

          private

          def print_configuration
            task_gid.nil? ? print_project(project) : print_task(project, task)
          end

          def update_configuration
            ensure_project_is_valid!
            ensure_task_is_valid! if task_gid
            config.path = path
          end

          def ensure_project_is_valid!
            abort "Invalid project: #{project_gid}" if project.nil?
          end

          def ensure_task_is_valid!
            abort "Invalid task: #{task_gid}" if task.nil?
          end

          def project
            @project ||= begin
              warn 'Fetching project...'
              api.get("projects/#{project_gid}", opt_fields: 'name,permalink_url')
            end
          end

          def task
            @task ||= begin
              warn 'Fetching task...'
              api.get("tasks/#{task_gid}", opt_fields: 'name,permalink_url')
            end
          end
        end
      end
    end
  end
end
