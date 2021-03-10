# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Readme < Abt::BaseCommand
        def self.usage
          "abt readme"
        end

        def self.description
          "Print markdown readme"
        end

        attr_reader :cli

        def perform
          puts(Abt::Docs::Markdown.readme)
        end
      end
    end
  end
end
