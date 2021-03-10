# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Commands < Abt::BaseCommand
        def self.usage
          'abt commands'
        end

        def self.description
          'List all abt commands'
        end

        attr_reader :cli

        def perform
          puts(Abt::Docs::Cli.commands)
        end
      end
    end
  end
end
