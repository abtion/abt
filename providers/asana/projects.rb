# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Projects
        def initialize(arg_str:, cli:); end

        def call
          puts(projects.map do |p|
            "asana:#{p['gid']} - #{p['name']}"
          end)
        end

        private

        def projects
          @projects ||= asana.get_paged('projects', workspace: Asana.workspace_gid, archived: false)
        end

        def asana
          Abt::Asana::Client
        end
      end
    end
  end
end
