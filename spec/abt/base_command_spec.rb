# frozen_string_literal: true

RSpec.describe Abt::BaseCommand do
  describe "flags" do
    context "subclass" do
      it "requires .usage to be implemented" do
        command = Class.new(Abt::BaseCommand)

        expect do
          command.usage
        end.to raise_error(NotImplementedError, "Command classes must implement .usage")
      end

      it "requires .description to be implemented" do
        command = Class.new(Abt::BaseCommand)

        expect do
          command.description
        end.to raise_error(NotImplementedError,
                           "Command classes must implement .description")
      end

      it "requires #perform to be implemented" do
        command = Class.new(Abt::BaseCommand) do
          def self.usage
            "command"
          end

          def self.description
            "Description"
          end
        end

        cli = Abt::Cli.new
        ari = Abt::Ari.new(scheme: "provider")
        command_instance = command.new(cli: cli, ari: ari)

        expect do
          command_instance.perform
        end.to raise_error(NotImplementedError,
                           "Command classes must implement #perform")
      end
    end

    context "when the command has invalid flags" do
      it "aborts with correct error message" do
        command = Class.new(Abt::BaseCommand) do
          def self.usage
            "command"
          end

          def self.description
            "Description"
          end

          def self.flags
            ["-f", "--flag", "Description"]
          end
        end

        cli = Abt::Cli.new
        ari = Abt::Ari.new(scheme: "provider", flags: ["--invalid-flag"])

        expect do
          command.new(cli: cli, ari: ari)
        end.to raise_error(Abt::Cli::Abort, "invalid option: --invalid-flag")
      end
    end
  end
end
