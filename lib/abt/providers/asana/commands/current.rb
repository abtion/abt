# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Current < BaseCommand
          def self.command
            'current asana[:<project-gid>[/<task-gid>]]'
          end

          def self.description
            'Get or set project and or task for current git repository'
          end

          def call
            if arg_str.nil?
              show_current_configuration
            else
              cli.warn 'Updating configuration'
              update_configuration
            end
          end

          private

          def show_current_configuration
            if project_gid.nil?
              cli.warn 'No project selected'
            elsif task_gid.nil?
              print_project(project)
            else
              print_task(project, task)
            end
          end

          def update_configuration
            ensure_project_is_valid!
            config.project_gid = project_gid

            if task_gid.nil?
              print_project(project)
              config.task_gid = nil
            else
              ensure_task_is_valid!
              config.task_gid task_gid

              print_task(project, task)
            end
          end

          def ensure_project_is_valid!
            cli.abort "Invalid project: #{project_gid}" if project.nil?
          end

          def ensure_task_is_valid!
            cli.abort "Invalid task: #{task_gid}" if task.nil?
          end

          def project
            @project ||= api.get("projects/#{project_gid}")
          end

          def task
            @task ||= api.get("tasks/#{task_gid}")
          end
        end
      end
    end
  end
end
