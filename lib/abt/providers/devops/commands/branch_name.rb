# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class BranchName < BaseCommand
          def self.usage
            'abt branch-name devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]'
          end

          def self.description
            'Suggest a git branch name for the current/specified work-item.'
          end

          def perform
            require_work_item!

            puts name
          rescue HttpError::NotFoundError
            args = [organization_name, project_name, board_id, work_item_id].compact
            warn 'Unable to find work item for configuration:'
            abort "devops:#{args.join('/')}"
          end

          private

          def name
            str = work_item['id']
            str += '-'
            str += work_item['name'].downcase.gsub(/[^\w]/, '-')
            str.gsub(/-+/, '-')
          end

          def work_item
            @work_item ||= begin
              work_item = api.get_paged('wit/workitems', ids: work_item_id)[0]
              sanitize_work_item(work_item)
            end
          end
        end
      end
    end
  end
end
