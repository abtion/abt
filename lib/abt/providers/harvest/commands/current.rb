# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Current < BaseCommand
          def self.command
            'current harvest[:<project-id>[/<task-id>]]'
          end

          def self.description
            'Get or set project and or task for current git repository'
          end

          def call
            if same_args_as_config? || !config.local_available?
              show_current_configuration
            else
              cli.warn 'Updating configuration'
              update_configuration
            end
          end

          private

          def show_current_configuration
            if project_id.nil?
              cli.warn 'No project selected'
            elsif task_id.nil?
              print_project(project)
            else
              print_task(project, task)
            end
          end

          def update_configuration
            ensure_project_is_valid!
            config.project_id = project_id

            if task_id.nil?
              print_project(project)
              config.task_id = nil
            else
              ensure_task_is_valid!
              config.task_id = task_id

              print_task(project, task)
            end
          end

          def ensure_project_is_valid!
            cli.abort "Invalid project: #{project_id}" if project.nil?
          end

          def ensure_task_is_valid!
            cli.abort "Invalid task: #{task_id}" if task.nil?
          end

          def project
            @project ||= api.get("projects/#{project_id}")
          end

          def task
            project_task_assignments
              .map { |assignment| assignment['task'] }
              .find { |task| task['id'].to_s == task_id }
          end

          def project_task_assignments
            @project_task_assignments ||= begin
              api.get_paged("projects/#{project_id}/task_assignments", is_active: true)
            rescue Abt::HttpError::HttpError # rubocop:disable Layout/RescueEnsureAlignment
              []
            end
          end
        end
      end
    end
  end
end
