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
          puts project['name']
          tasks.each do |task|
            puts [
              "asana:#{project['gid']}/#{task['gid']}",
              ' - ',
              task['name']
            ].join('')
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
            section = cli.prompt 'Which section?', sections
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
