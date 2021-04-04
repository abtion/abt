# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Clear, :asana) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)
  end

  it "clears the local git configuration" do
    local_git["path"] = "11111/22222"
    global_git["accessToken"] = "333333"

    err_output = StringIO.new
    output = null_tty
    argv = %w[clear asana]

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== CLEAR asana =====
      Configuration cleared
    TXT

    expect(local_git).to be_empty
    expect(global_git).not_to(be_empty)
  end

  context "when --global flags passed" do
    it "clears the global git configuration" do
      local_git["path"] = "11111/22222"
      global_git["accessToken"] = "333333"

      err_output = StringIO.new
      argv = %w[clear asana -g]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_tty)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== CLEAR asana -g =====
        Configuration cleared
      TXT

      expect(local_git).not_to(be_empty)
      expect(global_git).to be_empty
    end
  end

  context "when --all flags passed" do
    it "clears the all git configuration" do
      local_git["path"] = "11111/22222"
      global_git["accessToken"] = "333333"

      err_output = StringIO.new
      argv = %w[clear asana -a]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_tty)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== CLEAR asana -a =====
        Configuration cleared
      TXT

      expect(local_git).to be_empty
      expect(global_git).to be_empty
    end
  end

  context "when --all and --global flags passed" do
    it "clears the all git configuration" do
      local_git["path"] = "11111/22222"
      global_git["accessToken"] = "333333"

      argv = %w[clear asana -a -g]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, "Flags --global and --all cannot be used together")
      )
    end
  end
end
