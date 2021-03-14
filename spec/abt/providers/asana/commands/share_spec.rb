# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Share, :asana) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)
  end

  it "prints the current/specified ARI" do
    local_git["path"] = "11111/22222"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[share asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== SHARE asana =====
    TXT

    expect(output.string).to eq(<<~TXT)
      asana:11111/22222
    TXT
  end

  context "when no current/specified path" do
    it "outputs a relevant warning" do
      argv = %w[share asana]
      output = StringIO.new
      err_output = StringIO.new

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, output: output, input: null_tty, err_output: err_output)

      cli.perform

      expect(err_output.string).to(
        include("No configuration for project. Did you initialize Asana?")
      )
    end
  end
end
