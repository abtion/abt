# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class FindTask
        attr_reader :project_id, :cli

        def initialize(arg_str:, cli:)
          @project_id = Harvest.parse_arg_string(arg_str)[:project_id]
          @cli = cli
        end

        def call
          warn project['name']
          task = cli.prompt 'Select a task', tasks
          cli.print_provider_command('harvest', "#{project['id']}/#{task['id']}", task['name'])
        end

        private

        def project
          @project ||= harvest.get("projects/#{project_id}")
        end

        def tasks
          project_task_assignments.map { |assignment| assignment['task'] }
        end

        def project_task_assignments
          @project_task_assignments ||= begin
            harvest.get_paged("projects/#{project_id}/task_assignments", is_active: true)
                                        rescue Abt::HttpError::HttpError
                                          nil
          end
        end

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
