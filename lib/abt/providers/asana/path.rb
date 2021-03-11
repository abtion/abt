# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class Path < String
        PATH_REGEX = %r{^(?<project_gid>\d+)?/?(?<task_gid>\d+)?$}.freeze

        def self.from_ids(project_gid: nil, task_gid: nil)
          path = project_gid ? [project_gid, *task_gid].join("/") : ""
          new(path)
        end

        def initialize(path = "")
          raise Abt::Cli::Abort, "Invalid path: #{path}" unless PATH_REGEX.match?(path)

          super
        end

        def project_gid
          match[:project_gid]
        end

        def task_gid
          match[:task_gid]
        end

        private

        def match
          @match ||= PATH_REGEX.match(self)
        end
      end
    end
  end
end
