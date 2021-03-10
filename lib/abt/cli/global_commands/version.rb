# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Version < Abt::BaseCommand
        def self.usage
          'abt version'
        end

        def self.description
          'Print abt version'
        end

        attr_reader :cli

        def perform
          puts(Abt::VERSION)
        end
      end
    end
  end
end
