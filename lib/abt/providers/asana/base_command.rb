# frozen_string_literal: true

module Abt
  module Providers
    module Asana
      class BaseCommand < Abt::BaseCommand
        extend Forwardable

        attr_reader :path, :config

        def_delegators(:@path, :project_gid, :task_gid)

        def initialize(ari:, cli:)
          super

          @config = Configuration.new(cli: cli)

          @path = ari.path ? Path.new(ari.path) : config.path
        end

        private

        def require_local_config!
          abort("Must be run inside a git repository") unless config.local_available?
        end

        def require_project!
          abort("No current/specified project. Did you initialize Asana?") if project_gid.nil?
        end

        def require_task!
          abort("No current/specified project. Did you initialize Asana and pick a task?") if project_gid.nil?
          abort("No current/specified task. Did you pick an Asana task?") if task_gid.nil?
        end

        def print_project(project)
          cli.print_ari("asana", project["gid"], project["name"])
          warn(project["permalink_url"]) if project.key?("permalink_url") && cli.output.isatty
        end

        def print_task(project, task)
          project = { "gid" => project } if project.is_a?(String)
          cli.print_ari("asana", "#{project['gid']}/#{task['gid']}", task["name"])
          warn(task["permalink_url"]) if task.key?("permalink_url") && cli.output.isatty
        end

        def api
          Abt::Providers::Asana::Api.new(access_token: config.access_token)
        end
      end
    end
  end
end
