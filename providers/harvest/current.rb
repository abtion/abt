# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Current
        attr_reader :args, :project_id, :task_id

        def initialize(arg_str:, cli:)
          @args = Harvest.parse_arg_string(arg_str)
          @project_id = @args[:project_id]
          @task_id = @args[:task_id]
        end

        def call
          ensure_current_is_valid!

          Harvest.store_args(args)

          puts [
            "harvest:#{project['id']}/#{task['id']}",
            ' - ',
            "#{project['name']} > #{task['name']}"
          ].join('')
        end

        private

        def ensure_current_is_valid!
          if project_task_assignments.nil?
            abort "Invalid project id: #{project_id}"
          end

          if project_task_assignment.nil?
            abort "Task must belong to project: #{task_id}"
          end
        end

        def project
          project_task_assignment['project']
        end

        def task
          project_task_assignment['task']
        end

        def project_task_assignment
          @project_task_assignment ||= begin
            project_task_assignments.find { |a| a['task']['id'] == task_id }
          end
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
