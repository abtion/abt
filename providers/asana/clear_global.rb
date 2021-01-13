# frozen_string_literal: true

module Abt
  module Providers
    class Asana
      class ClearGlobal
        def initialize(**); end

        def call
          warn 'Clearing Asana project configuration'
          Asana.clear_global
        end
      end
    end
  end
end
