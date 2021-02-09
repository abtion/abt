# frozen_string_literal: true

module Abt
  module Providers
    module Git
      module Commands
        class Branch
          attr_reader :cli

          def self.command
            'branch git <provider>'
          end

          def self.description
            'Switch branch. Uses a compatible provider to generate the branch-name: E.g. `abt branch git asana`'
          end

          def initialize(cli:, **)
            @cli = cli
          end

          def perform
            create_and_switch unless switch
            cli.warn "Switched to #{branch_name}"
          end

          private

          def switch
            success = false
            Open3.popen3("git switch #{branch_name}") do |_i, _o, _error_output, thread|
              success = thread.value.success?
            end
            success
          end

          def create_and_switch
            cli.warn "No such branch: #{branch_name}"
            cli.abort('Aborting') unless cli.prompt.boolean 'Create branch?'

            Open3.popen3("git switch -c #{branch_name}") do |_i, _o, _e, thread|
              thread.value
            end
          end

          def branch_name # rubocop:disable Metrics/MethodLength
            @branch_name ||= begin
              if branch_names_from_providers.empty?
                cli.abort [
                  'None of the specified providers responded to `branch-name`.',
                  'Did you add compatible provider? e.g.:',
                  '   abt branch git asana',
                  '   abt branch git devops'
                ].join("\n")
              end

              if branch_names_from_providers.length > 1
                cli.abort [
                  'Got branch names from multiple providers, only one is supported',
                  'Branch names where:',
                  *branch_names_from_providers.map { |name| "   #{name}" }
                ].join("\n")
              end

              branch_names_from_providers.first
            end
          end

          def branch_names_from_providers
            input = StringIO.new(cli.args.join(' '))
            output = StringIO.new
            Abt::Cli.new(argv: ['branch-name'], output: output, input: input).perform

            output.string.lines.map(&:strip).compact
          end
        end
      end
    end
  end
end
