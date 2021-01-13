# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class ClearGlobal
        def self.command
          'clear-global asana'
        end

        def self.description
          'Clear all global configuration'
        end

        def initialize(**); end

        def call
          warn 'Clearing Asana project configuration'
          Asana.clear_global
        end
      end
    end
  end
end
