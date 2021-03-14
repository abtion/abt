# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Stop, :harvest) do
  let(:user_id) { harvest_credentials["userId"] }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).and_call_original
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)
  end

  it "stops the running harvest time entry and outputs it" do
    stub_request(:get,
                 "https://api.harvestapp.com/v2/time_entries?is_running=true&page=1&user_id=#{user_id}")
      .with(headers: request_headers_for_git_config(global_git))
      .to_return(body: Oj.dump({
                                 time_entries: [{
                                   id: "11111",
                                   project: { id: "22222", name: "Project name" },
                                   task: { id: "33333", name: "Task name" }
                                 }],
                                 total_pages: 1
                               }, mode: :json))

    stub_request(:patch, "https://api.harvestapp.com/v2/time_entries/11111/stop")
      .with(headers: request_headers_for_git_config(global_git))

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[stop harvest]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== STOP harvest =====
      Harvest time entry stopped
    TXT

    expect(output.string).to eq(<<~TXT)
      harvest:22222/33333 # Project name > Task name
    TXT
  end

  context "when there is no running time entry" do
    it "aborts with correct error message" do
      stub_request(:get,
                   "https://api.harvestapp.com/v2/time_entries?is_running=true&page=1&user_id=#{user_id}")
        .with(headers: request_headers_for_git_config(global_git))
        .to_return(body: Oj.dump({
                                   time_entries: [],
                                   total_pages: 1
                                 }, mode: :json))

      argv = %w[stop harvest]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "No running time entry")
    end
  end

  context "when failing to fetch running time entry" do
    it "aborts with correct error message" do
      stub_request(:get,
                   "https://api.harvestapp.com/v2/time_entries?is_running=true&page=1&user_id=#{user_id}")
        .with(headers: request_headers_for_git_config(global_git))
        .to_return(status: 500)

      argv = %w[stop harvest]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Unable to fetch running time entry")
    end
  end

  context "when failing to stop running time entry" do
    it "aborts with correct error message" do
      stub_request(:get,
                   "https://api.harvestapp.com/v2/time_entries?is_running=true&page=1&user_id=#{user_id}")
        .with(headers: request_headers_for_git_config(global_git))
        .to_return(body: Oj.dump({
                                   time_entries: [{ id: "11111" }],
                                   total_pages: 1
                                 }, mode: :json))

      stub_request(:patch, "https://api.harvestapp.com/v2/time_entries/11111/stop")
        .with(headers: request_headers_for_git_config(global_git))
        .to_return(status: 500)

      argv = %w[stop harvest]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Unable to stop time entry")
    end
  end
end
