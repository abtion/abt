# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class Clear
        def initialize(**); end

        def call
          warn 'Clearing Asana project configuration'
          Asana.clear
        end
      end
    end
  end
end
