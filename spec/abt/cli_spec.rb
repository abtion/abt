# frozen_string_literal: true

RSpec.describe Abt::Cli do
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

          cli = Abt::Cli.new argv: [command_name], output: output
          cli.perform

          expect(output.string).to eq(Abt::Docs::Cli.help)
        end
      end
    end

    describe 'examples' do
      it 'writes cli examples to output' do
        output = StringIO.new

        cli = Abt::Cli.new argv: ['examples'], output: output
        cli.perform

        expect(output.string).to eq(Abt::Docs::Cli.examples)
      end
    end

    describe 'commands' do
      it 'writes cli commands to output' do
        output = StringIO.new

        cli = Abt::Cli.new argv: ['commands'], output: output
        cli.perform

        expect(output.string).to eq(Abt::Docs::Cli.commands)
      end
    end

    describe 'readme' do
      it 'writes markdown readme to output' do
        output = StringIO.new

        cli = Abt::Cli.new argv: ['readme'], output: output
        cli.perform

        expect(output.string).to eq(Abt::Docs::Markdown.readme)
      end
    end
  end

  context 'when no ARI given' do
    it 'aborts with "No ARIs"' do
      cli = Abt::Cli.new argv: ['command']

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort, 'No ARIs')
    end

    context 'when no argument given through input IO' do
      it 'aborts with "No input from pipe"' do
        piped_argument = StringIO.new('')

        expect do
          Abt::Cli.new argv: ['share', 'asana:111/222'], input: piped_argument
        end.to raise_error(Abt::Cli::Abort, 'No input from pipe')
      end
    end
  end

  describe 'ARIs' do
    it 'correctly executes the matching provider command' do
      command = Class.new do
        def initialize(ari:, cli:); end

        def perform; end
      end
      provider = Module.new do
        @command = command

        def self.command_class(command_name)
          return @command if command_name == 'command'
        end
      end

      stub_const('Abt::Providers::Provider', provider) # Add the provider to Abt for only this spec

      command_instance = instance_double(command)

      allow(command).to receive(:new).and_return(command_instance)
      allow(command_instance).to receive(:perform)

      err_output = StringIO.new
      cli_instance = Abt::Cli.new(argv: ['command', 'provider:path', '--1', '--2'],
                                  err_output: err_output)
      cli_instance.perform

      expect(command).to have_received(:new) do |ari:, cli:|
        expect(ari.path).to eq('path')
        expect(ari.flags).to eq(['--1', '--2'])
        expect(cli).to eq(cli_instance)
      end
      expect(command_instance).to have_received(:perform)
      expect(err_output.string).to include('===== COMMAND provider:path --1 --2 =====')
    end

    context 'when ARI given through input IO (pipe)' do
      it 'uses the piped ARI' do
        piped_ari = StringIO.new('asana:111/222 # Description text')
        cli = Abt::Cli.new argv: ['share'], input: piped_ari, output: null_stream, err_output: null_stream

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |ari:, **|
          expect(ari.path).to eq('111/222')
        end
      end
    end

    context 'when no provider implements the command' do
      it 'aborts with "No providers found for command and ARI(s)"' do
        cli = Abt::Cli.new argv: ['invalid-command', 'asana:111/222']

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort, 'No providers found for command and ARI(s)')
      end
    end

    context 'when there are multiple commands for the same provider' do
      it 'drops subsequent commands and prints a warning' do
        err_output = StringIO.new
        cli = Abt::Cli.new(argv: ['share', 'asana:111', 'asana:222/333'],
                           err_output: err_output,
                           output: null_stream)

        allow(Abt::Providers::Asana::Commands::Share).to receive(:new).and_call_original

        cli.perform

        expect(Abt::Providers::Asana::Commands::Share).to have_received(:new).once do |ari:, **|
          expect(ari.path).to eq('111')
        end
        expect(err_output.string).to(
          include('Dropping command for already used scheme: asana:222/333')
        )
      end
    end

    context 'when at least one provider implements the command' do
      it 'does not abort' do
        cli = Abt::Cli.new argv: ['share', 'asana:111/222', 'git'], output: null_stream, err_output: null_stream

        expect do
          cli.perform
        end.not_to raise_error
      end
    end

    context 'when an ARI with flags is followed by another ARI' do
      it 'uses -- to separate the two ARIs' do
        provider1_command = Class.new do
          def initialize(*); end

          def perform; end
        end

        provider1 = Module.new do
          @command = provider1_command

          def self.command_class(command_name)
            return @command if command_name == 'command'
          end
        end

        provider2_command = Class.new do
          def initialize(*); end

          def perform; end
        end

        provider2 = Module.new do
          @command = provider2_command

          def self.command_class(command_name)
            return @command if command_name == 'command'
          end
        end

        stub_const('Abt::Providers::Provider1', provider1)
        stub_const('Abt::Providers::Provider2', provider2)

        allow(provider1_command).to receive(:new).and_call_original
        allow(provider2_command).to receive(:new).and_call_original

        err_output = StringIO.new
        argv = ['command', 'provider1:path1', '--1', '--', 'provider2:path2', '--2']

        cli_instance = Abt::Cli.new argv: argv, err_output: err_output
        cli_instance.perform

        expect(provider1_command).to have_received(:new) do |ari:, cli:|
          expect(ari.path).to eq('path1')
          expect(ari.flags).to eq(['--1'])
          expect(cli).to eq(cli_instance)
        end

        expect(provider2_command).to have_received(:new) do |ari:, cli:|
          expect(ari.path).to eq('path2')
          expect(ari.flags).to eq(['--2'])
          expect(cli).to eq(cli_instance)
        end
      end
    end

    context 'when command uses exit_with_message' do
      it 'outputs the message without exiting early' do
        command = Class.new do
          def initialize(ari:, cli:)
            @cli = cli
          end

          def perform
            @cli.exit_with_message('A message!')
          end
        end
        provider = Module.new do
          @command = command

          def self.command_class(command_name)
            return @command if command_name == 'command'
          end
        end

        stub_const('Abt::Providers::Provider', provider) # Add the provider to Abt for only this spec

        output = StringIO.new
        cli_instance = Abt::Cli.new(argv: ['command', 'provider:path'],
                                    err_output: null_stream,
                                    output: output)
        cli_instance.perform

        expect(output.string).to include('A message!')
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

  describe '#exit_with_message' do
    it 'raises an Abt::Cli::Abort with the given message' do
      cli = Abt::Cli.new

      expect do
        cli.exit_with_message('Exit!')
      end.to raise_error(Abt::Cli::Exit, 'Exit!')
    end
  end
end
