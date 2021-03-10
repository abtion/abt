# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Boards < BaseCommand
          def self.usage
            "abt boards devops"
          end

          def self.description
            "List all boards - useful for piping into grep etc"
          end

          def perform
            abort("No organization selected. Did you initialize DevOps?") if organization_name.nil?
            abort("No project selected. Did you initialize DevOps?") if project_name.nil?

            boards.map do |board|
              print_board(organization_name, project_name, board)
            end
          end

          private

          def boards
            @boards ||= api.get_paged("work/boards")
          end
        end
      end
    end
  end
end
