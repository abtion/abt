# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Set < BaseCommand
        def call
          if arg_str.nil?
            show_current_configuration
          else
            update_configuration
          end
        end

        private

        def show_current_configuration
          warn 'No configuration provided, current configuration is:'

          if task_id.nil?
            cli.print_provider_command(
              'harvest',
              project['id'].to_s,
              "#{project['client']['name']} > #{project['name']}"
            )
          else
            cli.print_provider_command(
              'harvest',
              "#{project['id']}/#{task['id']}",
              "#{project['name']} > #{task['name']}"
            )
          end
        end

        def update_configuration
          ensure_project_is_valid!
          remember_project_id(project_id)

          if task_id.nil?
            cli.print_provider_command(
              'harvest',
              project['id'].to_s,
              "#{project['client']['name']} > #{project['name']}"
            )
          else
            ensure_task_is_valid!
            remember_task_id(task_id)

            cli.print_provider_command(
              'harvest',
              "#{project['id']}/#{task['id']}",
              "#{project['name']} > #{task['name']}"
            )
          end
        end

        def ensure_project_is_valid!
          abort "Invalid project: #{project_id}" if project.nil?
        end

        def ensure_task_is_valid!
          abort "Invalid task: #{task_id}" if task.nil?
        end

        def project
          @project ||= Harvest.client.get("projects/#{project_id}")
        end

        def task
          project_task_assignments
            .map { |assignment| assignment['task'] }
            .find { |task| task['id'].to_s == task_id }
        end

        def project_task_assignments
          @project_task_assignments ||= begin
            Harvest.client.get_paged("projects/#{project_id}/task_assignments", is_active: true)
          rescue Abt::HttpError::HttpError # rubocop:disable Layout/RescueEnsureAlignment
            []
          end
        end
      end
    end
  end
end
