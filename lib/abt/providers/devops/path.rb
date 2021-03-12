# frozen_string_literal: true

module Abt
  module Providers
    module Devops
      class Path < String
        ORGANIZATION_NAME_REGEX = %r{(?<organization_name>[^/ ]+)}.freeze
        PROJECT_NAME_REGEX = %r{(?<project_name>[^/ ]+)}.freeze
        BOARD_ID_REGEX = /(?<board_id>[a-z0-9\-]+)/.freeze
        WORK_ITEM_ID_REGEX = /(?<work_item_id>\d+)/.freeze

        PATH_REGEX =
          %r{^(#{ORGANIZATION_NAME_REGEX}/#{PROJECT_NAME_REGEX}(/#{BOARD_ID_REGEX}(/#{WORK_ITEM_ID_REGEX})?)?)?}.freeze

        def self.from_ids(organization_name: nil, project_name: nil, board_id: nil, work_item_id: nil)
          return new unless organization_name && project_name && board_id

          new([organization_name, project_name, board_id, *work_item_id].join("/"))
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

        def board_id
          match[:board_id]
        end

        def work_item_id
          match[:work_item_id]
        end

        private

        def match
          @match ||= PATH_REGEX.match(self)
        end
      end
    end
  end
end
