# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      module Commands
        class Share < BaseCommand
          def self.command
            'share asana[:<project-gid>[/<task-gid>]]'
          end

          def self.description
            'Print project/task config string'
          end

          def call
            if project_gid.nil?
              cli.warn 'No project selected'
            elsif task_gid.nil?
              cli.print_provider_command('asana', project_gid)
            else
              cli.print_provider_command('asana', "#{project_gid}/#{task_gid}")
            end
          end
        end
      end
    end
  end
end