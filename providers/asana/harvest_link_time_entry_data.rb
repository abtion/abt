# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class HarvestLinkTimeEntryData < BaseCommand
        def call # rubocop:disable Metrics/MethodLength
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

          return if task['memberships'].any? { |m| m.dig('project', 'gid') == project_gid }

          abort "Invalid project gid: #{project_gid}"
        end

        def task
          @task ||= Asana.client.get("tasks/#{task_gid}")
        end
      end
    end
  end
end
