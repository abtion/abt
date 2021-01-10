# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Current
        attr_reader :args, :project_gid, :task_gid, :cli

        def initialize(arg_str:, cli:)
          @args = Asana.parse_arg_string(arg_str)
          @project_gid = @args[:project_gid]
          @task_gid = @args[:task_gid]
          @cli = cli
        end

        def call
          ensure_current_is_valid!

          Asana.store_args(args)

          cli.print_provider_command('asana', "#{project_gid}/#{task['gid']}", task['name'])
          puts task['permalink_url']
        end

        private

        def ensure_current_is_valid!
          abort "Invalid task gid: #{task_gid}" if task.nil?

          if task['memberships'].any? { |m| m.dig('project', 'gid') == project_gid }
            return
          end

          abort "Invalid project gid: #{project_gid}"
        end

        def task
          @task ||= asana.get("tasks/#{task_gid}")
        end

        def asana
          Abt::Asana::Client
        end
      end
    end
  end
end
