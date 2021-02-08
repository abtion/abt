# frozen_string_literal: true

RSpec.describe Abt::Cli do
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
