# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class ClearGlobal
        def self.command
          'clear-global harvest'
        end

        def self.description
          'Clear all global configuration'
        end

        def initialize(**); end

        def call
          warn 'Clearing Harvest project configuration'
          Harvest.clear_global
        end
      end
    end
  end
end
