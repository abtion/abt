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
            abort 'Must be run inside a git repository' unless config.local_available?

            require_project!
            ensure_valid_configuration!

            if path != config.path
              config.path = path
              warn 'Configuration updated'
            end

            print_configuration
          end

          private

          def print_configuration
            if task_id.nil?
              print_project(project)
            else
              print_task(project, task)
            end
          end

          def ensure_valid_configuration!
            abort "Invalid project: #{project_id}" if project.nil?
            abort "Invalid task: #{task_id}" if task_id && task.nil?
          end

          def project
            return @project if instance_variable_defined? :@project

            @project = if project_assignment
                         project_assignment['project'].merge('client' => project_assignment['client'])
                       end
          end

          def task
            return @task if instance_variable_defined? :@task

            @task = if project_assignment
                      project_assignment['task_assignments'].map { |ta| ta['task'] }.find do |task|
                        task['id'].to_s == task_id
                      end
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
