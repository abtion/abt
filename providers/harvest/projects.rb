# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Projects
        attr_reader :cli

        def initialize(cli:, **)
          @cli = cli
        end

        def call
          projects.map do |p|
            cli.print_provider_command('harvest', p['id'], "#{p['client']['name']} > #{p['name']}")
          end
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
