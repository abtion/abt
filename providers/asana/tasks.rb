# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Tasks
        attr_reader :project_gid, :cli

        def initialize(arg_str:, cli:)
          @project_gid = Asana.parse_arg_string(arg_str)[:project_gid]
          @cli = cli
        end

        def call
          warn project['name'] if cli.tty?
          tasks.each do |task|
            cli.print_provider_command('asana', "#{project['gid']}/#{task['gid']}", task['name'])
          end
        end

        private

        def project
          @project ||= begin
            asana.get("projects/#{project_gid}")
          end
        end

        def tasks
          @tasks ||= begin
            # Prompt the user for a section, unless if the command is being piped
            args = if cli.tty?
                     section = cli.prompt_choice 'Which section?', sections
                     { section: section['gid'] }
                   else
                     { project: project['gid'] }
                   end

            asana.get_paged('tasks', args)
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
