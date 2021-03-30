# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class BranchName < BaseCommand
          def self.usage
            "abt branch-name devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]"
          end

          def self.description
            "Suggest a git branch name for the current/specified work-item."
          end

          def perform
            require_work_item!

            if work_item
              puts name
            else
              abort(<<~TXT)
                Unable to find work item for configuration:
                devops:#{path}
              TXT
            end
          end

          private

          def name
            str = work_item["id"]
            str += "-"
            str += work_item["name"].downcase.gsub(/[^\w]/, "-")
            str.squeeze("-").gsub(/(^-|-$)/, "")
          end
        end
      end
    end
  end
end
