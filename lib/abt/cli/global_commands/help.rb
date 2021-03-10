# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Help < Abt::BaseCommand
        def self.usage
          "abt help"
        end

        def self.description
          "Print abt usage text"
        end

        attr_reader :cli

        def perform
          puts(Abt::Docs::Cli.help)
        end
      end
    end
  end
end
