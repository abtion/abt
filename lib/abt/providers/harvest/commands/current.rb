# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Current < BaseCommand
          def self.usage
            'abt current harvest[:<project-id>[/<task-id>]]'
          end

          def self.description
            'Get or set project and or task for current git repository'
          end

          def perform
            require_project!

            if path == config.path || !config.local_available?
              show_current_configuration
            else
              cli.warn 'Updating configuration'
              update_configuration
            end
          end

          private

          def show_current_configuration
            if task_id.nil?
              print_project(project)
            else
              print_task(project, task)
            end
          end

          def update_configuration
            ensure_project_is_valid!

            if task_id.nil?
              print_project(project)
            else
              ensure_task_is_valid!
              print_task(project, task)
            end

            config.path = path
          end

          def ensure_project_is_valid!
            cli.abort "Invalid project: #{project_id}" if project.nil?
          end

          def ensure_task_is_valid!
            cli.abort "Invalid task: #{task_id}" if task.nil?
          end

          def project
            @project ||= project_assignment['project'].merge('client' => project_assignment['client'])
          end

          def task
            @task ||= project_assignment['task_assignments'].map { |ta| ta['task'] }.find do |task|
              task['id'].to_s == task_id
            end
          end

          def project_assignment
            @project_assignment ||= begin
              project_assignments.find { |pa| pa['project']['id'].to_s == project_id }
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
