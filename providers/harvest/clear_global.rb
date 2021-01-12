# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class ClearGlobal
        def initialize(**); end

        def call
          warn 'Clearing Harvest project configuration'
          Harvest.clear_global
        end
      end
    end
  end
end
