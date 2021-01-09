# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class HarvestLinkTimeEntryData
        attr_reader :args, :project_gid, :task_gid

        def initialize(arg_str:, cli:)
          @args = Asana.parse_arg_string(arg_str)
          @project_gid = @args[:project_gid]
          @task_gid = @args[:task_gid]
        end

        def call
          ensure_current_is_valid!

          body = {
            notes: task['name'],
            external_reference: {
              id: task_gid.to_i,
              group_id: project_gid.to_i,
              permalink: task['permalink_url'],
              service: 'app.asana.com',
              service_icon_url: 'https://proxy.harvestfiles.com/production_harvestapp_public/uploads/platform_icons/app.asana.com.png'
            }
          }

          puts Oj.dump(body, mode: :json)
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
