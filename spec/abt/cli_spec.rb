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
  end

  context 'when provider argument given' do
    context 'when no provider implements the command' do
      it 'aborts with "No matching providers found for command"' do
        cli = Abt::Cli.new argv: ['invalid-command', 'asana:test/test']

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::AbortError, 'No matching providers found for command')
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
