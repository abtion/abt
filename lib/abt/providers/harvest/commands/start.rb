# frozen_string_literal: true

require_relative 'track'

module Abt
  module Providers
    module Harvest
      module Commands
        class Start < Track
          def self.usage
            'abt start harvest[:<project-id>/<task-id>] [options]'
          end

          def self.description
            'Alias for: `abt track harvest`. Meant to used in combination other scheme arguments, e.g. `abt start harvest asana`'
          end
        end
      end
    end
  end
end
