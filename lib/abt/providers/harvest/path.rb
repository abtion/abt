# frozen_string_literal: true

module Abt
  module Providers
    module Harvest
      class Path < String
        PATH_REGEX = %r{^(?<project_id>\d+)?/?(?<task_id>\d+)?$}.freeze

        def self.from_ids(project_id = nil, task_id = nil)
          path = project_id ? [project_id, *task_id].join("/") : ""
          new(path)
        end

        def initialize(path = "")
          raise Abt::Cli::Abort, "Invalid path: #{path}" unless PATH_REGEX.match?(path)

          super
        end

        def project_id
          match[:project_id]
        end

        def task_id
          match[:task_id]
        end

        private

        def match
          @match ||= PATH_REGEX.match(self)
        end
      end
    end
  end
end
