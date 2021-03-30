# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Path < String
        ORGANIZATION_NAME_REGEX = %r{(?<organization_name>[^/ ]+)}.freeze
        PROJECT_NAME_REGEX = %r{(?<project_name>[^/ ]+)}.freeze
        TEAM_NAME_REGEX = %r{(?<team_name>[^/ ]+)}.freeze
        BOARD_NAME_REGEX = %r{(?<board_name>[^/ ]+)}.freeze
        WORK_ITEM_ID_REGEX = /(?<work_item_id>\d+)/.freeze

        PATH_REGEX =
          %r{^(#{ORGANIZATION_NAME_REGEX}/#{PROJECT_NAME_REGEX}(/#{TEAM_NAME_REGEX}(/#{BOARD_NAME_REGEX}(/#{WORK_ITEM_ID_REGEX})?)?)?)?}.freeze # rubocop:disable Layout/LineLength

        def self.from_ids(organization_name: nil, project_name: nil, team_name: nil, board_name: nil, work_item_id: nil)
          return new unless organization_name && project_name

          parts = [organization_name, project_name]

          if team_name
            parts << team_name

            if board_name
              parts << board_name
              parts << work_item_id if work_item_id
            end
          end

          new(parts.join("/"))
        end

        def initialize(path = "")
          raise Abt::Cli::Abort, "Invalid path: #{path}" unless PATH_REGEX.match?(path)

          super
        end

        def organization_name
          match[:organization_name]
        end

        def project_name
          match[:project_name]
        end

        def team_name
          match[:team_name]
        end

        def board_name
          match[:board_name]
        end

        def work_item_id
          match[:work_item_id]
        end

        private

        def match
          @match ||= PATH_REGEX.match(to_s)
        end
      end
    end
  end
end
