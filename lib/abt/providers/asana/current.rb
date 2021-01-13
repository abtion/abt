# frozen_string_literal: true

module Abt
  module Providers
    class Asana
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
            warn 'Updating configuration'
            update_configuration
          end
        end

        private

        def show_current_configuration
          if project_gid.nil?
            warn 'No project selected'
          elsif task_gid.nil?
            cli.print_provider_command('asana', project['gid'], project['name'])
          else
            cli.print_provider_command('asana', "#{project_gid}/#{task['gid']}", task['name'])
          end
        end

        def update_configuration
          ensure_project_is_valid!
          remember_project_gid(project_gid)

          if task_gid.nil?
            cli.print_provider_command('asana', project['gid'], project['name'])
          else
            ensure_task_is_valid!
            remember_task_gid(task_gid)

            cli.print_provider_command('asana', "#{project_gid}/#{task['gid']}", task['name'])
          end
        end

        def ensure_project_is_valid!
          abort "Invalid project: #{project_gid}" if project.nil?
        end

        def ensure_task_is_valid!
          abort "Invalid task: #{task_gid}" if task.nil?
        end

        def project
          @project ||= Asana.client.get("projects/#{project_gid}")
        end

        def task
          @task ||= Asana.client.get("tasks/#{task_gid}")
        end
      end
    end
  end
end
