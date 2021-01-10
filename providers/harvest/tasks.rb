# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Tasks
        attr_reader :project_id, :cli

        def initialize(arg_str:, cli:)
          @project_id = Harvest.parse_arg_string(arg_str)[:project_id]
          @cli = cli
        end

        def call
          project_task_assignments.each do |a|
            project = a['project']
            task = a['task']

            cli.print_provider_command(
              'harvest',
              "#{project['id']}/#{task['id']}",
              "#{project['name']} > #{task['name']}"
            )
          end
        end

        private

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
