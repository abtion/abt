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
            'Print project/task ARI'
          end

          def perform
            if path != ''
              cli.print_ari('harvest', path)
            elsif cli.output.isatty
              warn 'No configuration for project. Did you initialize Harvest?'
            end
          end
        end
      end
    end
  end
end
