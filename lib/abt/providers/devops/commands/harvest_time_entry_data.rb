# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class HarvestTimeEntryData < BaseCommand
          def self.usage
            'abt harvest-time-entry-data devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]'
          end

          def self.description
            'Print Harvest time entry data for DevOps work item as json. Used by harvest start script.'
          end

          def perform
            require_work_item!

            body = {
              notes: notes,
              external_reference: {
                id: work_item['id'],
                group_id: 'AzureDevOpsWorkItem',
                permalink: work_item['url']
              }
            }

            puts Oj.dump(body, mode: :json)
          rescue HttpError::NotFoundError
            args = [organization_name, project_name, board_id, work_item_id].compact

            error_message = [
              'Unable to find work item for configuration:',
              "devops:#{args.join('/')}"
            ].join("\n")
            abort error_message
          end

          private

          def notes
            [
              'Azure DevOps',
              work_item['fields']['System.WorkItemType'],
              "##{work_item['id']}",
              '-',
              work_item['name']
            ].join(' ')
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
