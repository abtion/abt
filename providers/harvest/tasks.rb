# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Tasks
        attr_reader :path

        def initialize(path = '')
          @path = path
        end

        def call
          Current.new(path).call

          project_task_assignments.each do |a|
            project = a['project']
            task = a['task']

            puts [
              "harvest:#{project['id']}/#{task['id']}",
              ' - ',
              "#{project['name']} > #{task['name']}"
            ].join('')
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

        def project_id
          Abt::GitConfig.local('abt.harvest.projectId')
        end

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
