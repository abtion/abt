# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      module Commands
        class Share < BaseCommand
          def self.usage
            'abt share harvest[:<project-id>[/<task-id>]]'
          end

          def self.description
            'Print project/task config string'
          end

          def perform
            if project_id.nil?
              cli.warn 'No project selected'
            elsif task_id.nil?
              cli.print_scheme_argument('harvest', project_id)
            else
              cli.print_scheme_argument('harvest', "#{project_id}/#{task_id}")
            end
          end
        end
      end
    end
  end
end
