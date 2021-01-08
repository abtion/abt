# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Projects
        def call
          puts(projects.map do |p|
            "harvest:#{p['id']} - #{p['client']['name']} > #{p['name']}"
          end)
        end

        private

        def projects
          @projects ||= harvest.get_paged('projects', is_active: true)
        end

        def harvest
          Abt::Harvest::Client
        end
      end
    end
  end
end
