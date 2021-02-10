# frozen_string_literal: true

RSpec.describe Abt::Cli do
  def null_stream
    StringIO.new
  end

  context 'when no command given' do
    it 'writes "no command specified" to err_output and help to output' do
      allow(Abt::Docs::Cli).to receive(:help).and_return('Help content')

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

    ['--help', '-h', 'help'].each do |command_name|
      describe command_name do
        it 'writes cli help to output' do
          output = StringIO.new

          allow(Abt::Docs::Cli).to receive(:help).and_return('Help content')

          cli = Abt::Cli.new argv: [command_name], output: output
          cli.perform

          expect(output.string).to eq("Help content\n")
        end
      end
    end

    describe 'examples' do
      it 'writes cli examples to output' do
        output = StringIO.new

        allow(Abt::Docs::Cli).to receive(:examples).and_return('Examples content')

        cli = Abt::Cli.new argv: ['examples'], output: output
        cli.perform

        expect(output.string).to eq("Examples content\n")
      end
    end

    describe 'commands' do
      it 'writes cli commands to output' do
        output = StringIO.new

        allow(Abt::Docs::Cli).to receive(:commands).and_return('Commands content')

        cli = Abt::Cli.new argv: ['commands'], output: output
        cli.perform

        expect(output.string).to eq("Commands content\n")
      end
    end

    describe 'readme' do
      it 'writes markdown readme to output' do
        output = StringIO.new

        allow(Abt::Docs::Markdown).to receive(:readme).and_return('# Readme')

        cli = Abt::Cli.new argv: ['readme'], output: output
        cli.perform

        expect(output.string).to eq("# Readme\n")
      end
    end
  end

  context 'when no provider argument given' do
    it 'aborts with "No provider arguments"' do
      cli = Abt::Cli.new argv: ['command']

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort, 'No provider arguments')
    end

    context 'when no argument given through input IO' do
      it 'aborts with "No input from pipe"' do
        piped_argument = StringIO.new('')

        expect do
          Abt::Cli.new argv: ['share', 'asana:test/test'], input: piped_argument
        end.to raise_error(Abt::Cli::Abort, 'No input from pipe')
      end
    end
  end

  describe 'provider arguments' do
    it 'correctly executes the command for the provider' do
      Command = Class.new do
        def initialize(path:, flags:, cli:); end

        def perform; end
      end
      Provider = Module.new do
        def self.command_class(command_name)
          return Command if command_name == 'command'
        end
      end

      stub_const('Abt::Providers::Provider', Provider) # Add the provider to Abt for only this spec

      command_instance = instance_double(Command)

      allow(Command).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(:perform)

      err_output = StringIO.new
      cli_instance = Abt::Cli.new(argv: ['command', 'provider:path', '--1', '--2'],
                                  err_output: err_output)
      cli_instance.perform

      expect(Command).to have_received(:new) do |path:, flags:, cli:|
        expect(path).to eq('path')
        expect(flags).to eq(['--1', '--2'])
        expect(cli).to eq(cli_instance)
      end
      expect(command_instance).to have_received(:perform)
      expect(err_output.string).to include('===== COMMAND PROVIDER:PATH =====')
    end

    context 'when provider argument given through input IO (pipe)' do
      it 'uses the piped argument' do
        piped_argument = StringIO.new('asana:test/test # Description text from other command')
        cli = Abt::Cli.new argv: ['share'], input: piped_argument, output: null_stream, err_output: null_stream

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |path:, **|
          expect(path).to eq('test/test')
        end
      end
    end

    context 'when no provider implements the command' do
      it 'aborts with "No matching providers found for command"' do
        cli = Abt::Cli.new argv: ['invalid-command', 'asana:test/test']

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort, 'No matching providers found for command')
      end
    end

    context 'when there are multiple commands for the same provider' do
      it 'drops subsequent commands and prints a warning' do
        err_output = StringIO.new
        cli = Abt::Cli.new(argv: ['share', 'asana:called', 'asana:not/called'],
                           err_output: err_output,
                           output: null_stream)

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |path:, **|
          expect(path).to eq('called')
        end
        expect(err_output.string).to(
          include('Dropping command for already used provider: asana:not/called')
        )
      end
    end

    context 'when at least one provider implements the command' do
      it 'does not abort' do
        cli = Abt::Cli.new argv: ['share', 'asana:test/test', 'git'], output: null_stream, err_output: null_stream

        expect do
          cli.perform
        end.not_to raise_error
      end
    end

    context 'when there\'s a provider argument after an argument with flags' do
      it 'uses -- to separate the two providers' do
        Provider1Command = Class.new do
          def initialize(*); end

          def perform; end
        end

        Provider1 = Module.new do
          def self.command_class(command_name)
            return Provider1Command if command_name == 'command'
          end
        end

        Provider2Command = Class.new do
          def initialize(*); end

          def perform; end
        end

        Provider2 = Module.new do
          def self.command_class(command_name)
            return Provider2Command if command_name == 'command'
          end
        end

        stub_const('Abt::Providers::Provider1', Provider1)
        stub_const('Abt::Providers::Provider2', Provider2)

        allow(Provider1Command).to receive(:new).and_call_original
        allow(Provider2Command).to receive(:new).and_call_original

        err_output = StringIO.new
        argv = ['command', 'provider1:path1', '--1', '--', 'provider2:path2', '--2']

        cli_instance = Abt::Cli.new argv: argv, err_output: err_output
        cli_instance.perform

        expect(Provider1Command).to have_received(:new) do |path:, flags:, cli:|
          expect(path).to eq('path1')
          expect(flags).to eq(['--1'])
          expect(cli).to eq(cli_instance)
        end

        expect(Provider2Command).to have_received(:new) do |path:, flags:, cli:|
          expect(path).to eq('path2')
          expect(flags).to eq(['--2'])
          expect(cli).to eq(cli_instance)
        end
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
    it 'raises an Abt::Cli::Abort with the given message' do
      cli = Abt::Cli.new

      expect do
        cli.abort('Error!')
      end.to raise_error(Abt::Cli::Abort, 'Error!')
    end
  end
end
