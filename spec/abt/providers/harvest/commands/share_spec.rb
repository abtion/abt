# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Share, :harvest) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)
  end

  it "prints the current/specified ARI" do
    local_git["path"] = "11111/22222"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[share harvest]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== SHARE harvest =====
    TXT

    expect(output.string).to eq(<<~TXT)
      harvest:11111/22222
    TXT
  end

  context "when no current/specified path" do
    it "outputs a relevant warning" do
      argv = %w[share harvest]
      output = StringIO.new
      err_output = StringIO.new

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, output: output, input: null_tty, err_output: err_output)

      cli.perform

      expect(err_output.string).to(
        include("No configuration for project. Did you initialize Harvest?")
      )
    end
  end
end
