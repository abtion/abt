# frozen_string_literal: true

RSpec.describe Abt::Cli::BaseCommand do
  describe 'flags' do
    context 'subclass' do
      it 'requires .usage to be implemented' do
        command = Class.new(Abt::Cli::BaseCommand)

        expect { command.usage }.to raise_error(NotImplementedError, 'Command classes must implement .usage')
      end

      it 'requires .description to be implemented' do
        command = Class.new(Abt::Cli::BaseCommand)

        expect { command.description }.to raise_error(NotImplementedError, 'Command classes must implement .description')
      end

      it 'requires #perform to be implemented' do
        command = Class.new(Abt::Cli::BaseCommand) do
          def self.usage
            'command'
          end

          def self.description
            'Description'
          end
        end

        cli = Abt::Cli.new
        ari = Abt::Cli::Ari.new(scheme: 'provider')
        command_instance = command.new(cli: cli, ari: ari)

        expect { command_instance.perform }.to raise_error(NotImplementedError, 'Command classes must implement #perform')
      end
    end

    context 'when the command has invalid flags' do
      it 'aborts with correct error message' do
        command = Class.new(Abt::Cli::BaseCommand) do
          def self.usage
            'command'
          end

          def self.description
            'Description'
          end

          def self.flags
            ['-f', '--flag', 'Description']
          end
        end

        cli = Abt::Cli.new
        ari = Abt::Cli::Ari.new(scheme: 'provider', flags: ['--invalid-flag'])

        expect { command.new(cli: cli, ari: ari) }.to raise_error(Abt::Cli::Abort, 'invalid option: --invalid-flag')
      end
    end
  end
end
