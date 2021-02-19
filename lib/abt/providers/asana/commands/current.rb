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
            abort 'Must be run inside a git repository' unless config.local_available?

            require_project!
            ensure_valid_configuration!

            if path != config.path
              warn 'Updating configuration'
              config.path = path
            end

            print_configuration
          end

          private

          def print_configuration
            task_gid.nil? ? print_project(project) : print_task(project, task)
          end

          def ensure_valid_configuration!
            abort "Invalid project: #{project_gid}" if project.nil?
            abort "Invalid task: #{task_gid}" if task_gid && task.nil?
          end

          def project
            @project ||= begin
              warn 'Fetching project...'
              api.get("projects/#{project_gid}", opt_fields: 'name,permalink_url')
                         rescue Abt::HttpError::NotFoundError
                           nil
            end
          end

          def task
            @task ||= begin
              warn 'Fetching task...'
              api.get("tasks/#{task_gid}", opt_fields: 'name,permalink_url')
                      rescue Abt::HttpError::NotFoundError
                        nil
            end
          end
        end
      end
    end
  end
end
