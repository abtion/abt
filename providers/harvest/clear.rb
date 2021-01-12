# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      class Clear
        def initialize(**); end

        def call
          warn 'Clearing Harvest project configuration'
          Harvest.clear
        end
      end
    end
  end
end
