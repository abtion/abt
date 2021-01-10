# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Projects
        attr_reader :cli

        def initialize(cli:, **)
          @cli = cli
        end

        def call
          projects.map do |project|
            cli.print_provider_command('asana', project['gid'], project['name'])
          end
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
