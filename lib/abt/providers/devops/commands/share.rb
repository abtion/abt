# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      module Commands
        class Share < BaseCommand
          def self.usage
            'abt share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]'
          end

          def self.description
            'Print DevOps ARI'
          end

          def perform
            if path != ''
              cli.print_ari('devops', path)
            elsif cli.output.isatty
              warn 'No configuration for project. Did you initialize DevOps?'
            end
          end
        end
      end
    end
  end
end
