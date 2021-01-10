# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Move
        attr_reader :arg_str, :cli

        def initialize(arg_str:, cli:)
          @arg_str = arg_str
          @cli = cli
        end

        def call
          Current.new(arg_str: arg_str, cli: cli).call

          move_task

          puts "Asana task moved to #{section['name']}"
        rescue Abt::HttpError::HttpError => e
          puts e
          abort 'Unable to move asana task'
        end

        private

        def move_task
          body = { data: { task: Abt::GitConfig.local('abt.asana.taskGid') } }
          body_json = Oj.dump(body, mode: :json)
          asana.post("sections/#{section['gid']}/addTask", body_json)
        end

        def section
          @section ||= cli.prompt 'Move asana task to?', sections
        end

        def project_gid
          Abt::GitConfig.local('abt.asana.projectGid')
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
