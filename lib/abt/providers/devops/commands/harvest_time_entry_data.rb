# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class HarvestTimeEntryData < BaseCommand
          def self.usage
            "abt harvest-time-entry-data devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]"
          end

          def self.description
            "Print Harvest time entry data for DevOps work item as json. Used by harvest start script."
          end

          def perform
            require_work_item!

            if work_item
              puts Oj.dump(body, mode: :json)
            else
              abort(<<~TXT)
                Unable to find work item for configuration:
                devops:#{path}
              TXT
            end
          end

          private

          def body
            {
              notes: notes,
              external_reference: {
                id: work_item["id"],
                group_id: "AzureDevOpsWorkItem",
                permalink: work_item["url"]
              }
            }
          end

          def notes
            [
              "Azure DevOps",
              work_item["fields"]["System.WorkItemType"],
              "##{work_item['id']}",
              "-",
              work_item["name"]
            ].join(" ")
          end
        end
      end
    end
  end
end
