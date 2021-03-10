# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Examples < Abt::BaseCommand
        def self.usage
          "abt examples"
        end

        def self.description
          "Print command examples"
        end

        attr_reader :cli

        def perform
          puts(Abt::Docs::Cli.examples)
        end
      end
    end
  end
end
