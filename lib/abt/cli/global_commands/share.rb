# frozen_string_literal: true

module Abt
  class Cli
    module GlobalCommands
      class Share < Abt::BaseCommand
        def self.usage
          'abt share'
        end

        def self.description
          'Prints all project configuration as a single line of ARIs'
        end

        attr_reader :cli

        def perform
          warn 'Printing project configuration'
          puts share_string
        end

        def share_string
          @share_string ||= begin
            aris = Abt.schemes.join(' ')

            input = StringIO.new(aris)
            output = StringIO.new
            Abt::Cli.new(argv: ['share'], output: output, input: input).perform

            output.string.strip.gsub(/\s+/, ' ')
          end
        end
      end
    end
  end
end
