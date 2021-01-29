# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Share < BaseCommand
          def self.command
            'share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]'
          end

          def self.description
            'Print DevOps config string'
          end

          def call
            if organization_name.nil?
              cli.warn 'No organization selected'
            elsif project_name.nil?
              cli.warn 'No project selected'
            elsif board_id.nil?
              cli.warn 'No board selected'
            else
              args = [organization_name, project_name, board_id, work_item_id].compact
              cli.print_provider_command('devops', args.join('/'))
            end
          end
        end
      end
    end
  end
end
