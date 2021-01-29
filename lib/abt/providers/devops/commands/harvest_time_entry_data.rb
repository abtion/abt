# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class HarvestTimeEntryData < BaseCommand
          def self.command
            'harvest-time-entry-data deveops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]'
          end

          def self.description
            'Print Harvest time entry data for DevOps work item as json. Used by harvest start script.'
          end

          def call
            body = {
              notes: notes,
              external_reference: {
                id: work_item['id'],
                group_id: 'AzureDevOpsWorkItem',
                permalink: work_item['url']
              }
            }

            cli.puts Oj.dump(body, mode: :json)
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
