# frozen_string_literal: true

module Abt
  module Providers
    module Git
      module Commands
        class Branch < Abt::BaseCommand
          def self.usage
            "abt branch git <scheme>[:<path>]"
          end

          def self.description
            "Switch branch. Uses a compatible scheme to generate the branch-name: E.g. `abt branch git asana`"
          end

          def perform
            switch || create_and_switch
            warn("Switched to #{branch_name}")
          end

          private

          def switch
            success = false
            Open3.popen3("git switch #{branch_name}") do |_i, _o, _e, thread|
              success = thread.value.success?
            end
            success
          end

          def create_and_switch
            warn("No such branch: #{branch_name}")
            abort("Aborting") unless cli.prompt.boolean("Create branch?")

            Open3.popen3("git switch -c #{branch_name}") do |_i, _o, _e, thread|
              thread.value
            end
          end

          def branch_name # rubocop:disable Metrics/MethodLength
            @branch_name ||= begin
              if branch_names_from_aris.empty?
                abort([
                  "None of the specified ARIs responded to `branch-name`.",
                  "Did you add compatible scheme? e.g.:",
                  "   abt branch git asana",
                  "   abt branch git devops"
                ].join("\n"))
              end

              if branch_names_from_aris.length > 1
                abort([
                  "Got branch names from multiple ARIs, only one is supported",
                  "Branch names were:",
                  *branch_names_from_aris.map { |name| "   #{name}" }
                ].join("\n"))
              end

              branch_names_from_aris.first
            end
          end

          def branch_names_from_aris
            abort("You must provide an additional ARI that responds to: branch-name. E.g., asana") if other_aris.empty?

            input = StringIO.new(cli.aris.to_s)
            output = StringIO.new
            Abt::Cli.new(argv: ["branch-name"], output: output, input: input).perform

            output.string.lines.map(&:strip).compact
          end

          def other_aris
            @other_aris ||= cli.aris - [ari]
          end
        end
      end
    end
  end
end
