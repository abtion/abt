# frozen_string_literal: true

RSpec.describe Abt::Cli do
  context 'when no command given' do
    it 'writes "no command specified" to err_output and help to output' do
      allow(Abt::Docs::Cli).to receive(:content).and_return('Help content')

      output = StringIO.new
      err_output = StringIO.new
      cli = Abt::Cli.new argv: [], err_output: err_output, output: output

      cli.perform

      expect(output.string).to eq("Help content\n")
      expect(err_output.string).to eq("No command specified\n\n")
    end
  end

  describe 'global commands' do
    ['--version', '-v', 'version'].each do |command_name|
      describe command_name do
        it 'prints the version' do
          stub_const('Abt::VERSION', '1.1.1')

          output = StringIO.new
          cli = Abt::Cli.new(argv: [command_name], output: output)
          cli.perform

          expect(output.string).to eq("1.1.1\n")
        end
      end
    end

    ['--help', '-h', 'help', 'commands'].each do |command_name|
      describe command_name do
        it 'writes cli docs to output' do
          output = StringIO.new

          allow(Abt::Docs::Cli).to receive(:content).and_return('Help content')

          cli = Abt::Cli.new argv: [command_name], output: output
          cli.perform

          expect(output.string).to eq("Help content\n")
        end
      end
    end

    describe 'help-md' do
      it 'writes markdown docs to output' do
        output = StringIO.new

        allow(Abt::Docs::Markdown).to receive(:content).and_return('# Markdown help content')

        cli = Abt::Cli.new argv: ['help-md'], output: output
        cli.perform

        expect(output.string).to eq("# Markdown help content\n")
      end
    end
  end

  context 'when no provider argument given' do
    it 'aborts with "No provider arguments"' do
      cli = Abt::Cli.new argv: ['command']

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::AbortError, 'No provider arguments')
    end

    context 'when no argument given through input IO' do
      it 'aborts with "No input from pipe"' do
        piped_argument = StringIO.new('')

        expect do
          Abt::Cli.new argv: ['share', 'asana:test/test'], input: piped_argument
        end.to raise_error(Abt::Cli::AbortError, 'No input from pipe')
      end
    end
  end

  context 'when provider argument given' do
    it 'correctly executes the command for the provider' do
      Provider = Module.new do
        class Command
          def initialize(arg_str:, cli:); end

          def perform; end
        end

        def self.command_class(command_name)
          return Command if command_name == 'command'
        end
      end

      stub_const('Abt::Providers::Provider', Provider) # Add the provider to Abt for only this spec

      Command = Provider.const_get(:Command) # Provider::Command doesn't work
      command_instance = instance_double(Command)

      allow(Command).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(:perform)

      cli_instance = Abt::Cli.new argv: ['command', 'provider:arg_str']
      cli_instance.perform

      expect(Command).to have_received(:new) do |arg_str:, cli:|
        expect(arg_str).to eq('arg_str')
        expect(cli).to eq(cli_instance)
      end
      expect(command_instance).to have_received(:perform)
    end

    context 'when provider argument given through input IO (pipe)' do
      it 'uses the piped argument' do
        piped_argument = StringIO.new('asana:test/test # Description text from other command')
        cli = Abt::Cli.new argv: ['share'], input: piped_argument

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |arg_str:, **|
          expect(arg_str).to eq('test/test')
        end
      end
    end

    context 'when no provider implements the command' do
      it 'aborts with "No matching providers found for command"' do
        cli = Abt::Cli.new argv: ['invalid-command', 'asana:test/test']

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::AbortError, 'No matching providers found for command')
      end
    end

    context 'when there are multiple commands for the same provider' do
      it 'drops subsequent commands and prints a warning' do
        err_output = StringIO.new
        cli = Abt::Cli.new(argv: ['share', 'asana:called', 'asana:not/called'],
                           err_output: err_output)

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |arg_str:, **|
          expect(arg_str).to eq('called')
        end
        expect(err_output.string).to(
          include('Dropping command for already used provider: asana:not/called')
        )
      end
    end

    context 'when at least one provider implements the command' do
      it 'does not abort' do
        cli = Abt::Cli.new argv: ['share', 'asana:test/test', 'git']

        expect do
          cli.perform
        end.not_to raise_error
      end
    end
  end

  describe '#warn' do
    it 'prints a line to err_output' do
      err_output = StringIO.new

      cli = Abt::Cli.new err_output: err_output
      cli.warn('test')

      expect(err_output.string).to eq("test\n")
    end
  end

  describe '#puts' do
    it 'prints a line to output' do
      output = StringIO.new

      cli = Abt::Cli.new output: output
      cli.puts('test')

      expect(output.string).to eq("test\n")
    end
  end

  describe '#print' do
    it 'prints a string to output' do
      output = StringIO.new

      cli = Abt::Cli.new output: output
      cli.print('test')

      expect(output.string).to eq('test')
    end
  end

  describe '#abort' do
    it 'raises an Abt::Cli::AbortError with the given message' do
      cli = Abt::Cli.new

      expect do
        cli.abort('Error!')
      end.to raise_error(Abt::Cli::AbortError, 'Error!')
    end
  end
end
