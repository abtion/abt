# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class FindTask
        attr_reader :project_gid, :cli

        def initialize(arg_str:, cli:)
          @project_gid = Asana.parse_arg_string(arg_str)[:project_gid]
          @cli = cli
        end

        def call
          warn project['name']
          task = cli.prompt_choice 'Select a task', tasks
          cli.print_provider_command('asana', "#{project_gid}/#{task['gid']}", task['name'])
        end

        private

        def project
          @project ||= begin
            asana.get("projects/#{project_gid}")
          end
        end

        def tasks
          @tasks ||= begin
            section = cli.prompt_choice 'Which section?', sections
            asana.get_paged('tasks', section: section['gid'])
          end
        end

        def sections
          asana.get_paged("projects/#{project_gid}/sections")
        rescue Abt::HttpError::HttpError
          []
        end

        def asana
          Abt::Asana::Client
        end
      end
    end
  end
end
