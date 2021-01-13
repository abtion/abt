# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Clear
        def self.command
          'clear asana'
        end

        def self.description
          'Clear project/task for current git repository'
        end

        def initialize(**); end

        def call
          warn 'Clearing Asana project configuration'
          Asana.clear
        end
      end
    end
  end
end
