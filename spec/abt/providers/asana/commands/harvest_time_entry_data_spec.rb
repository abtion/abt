# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::HarvestTimeEntryData, :asana) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

    stub_asana_request(global_git, :get, "tasks/22222")
      .with(query: { opt_fields: "name,permalink_url,memberships.project" })
      .to_return(body: Oj.dump({ data: { gid: "22222",
                                         name: "A long task \#$\#$ name",
                                         permalink_url: "https://ta.sk/22222/URL",
                                         memberships: [{ project: { gid: "11111" } }] } },
                               mode: :json))
  end

  it "prints data that can be merged into a harvest time entry to link it to the task" do
    local_git["path"] = "11111/22222"

    err_output = StringIO.new
    output = null_tty
    argv = %w[harvest-time-entry-data asana]

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== HARVEST-TIME-ENTRY-DATA asana =====
      Fetching task...
    TXT
    expect(Oj.load(output.string, symbol_keys: true)).to eq(
      notes: "A long task \#$\#$ name",
      external_reference: {
        id: 22_222,
        group_id: 11_111,
        permalink: "https://ta.sk/22222/URL"
      }
    )
  end

  context "when ARI doesn't include a task" do
    it "aborts with correct message" do
      local_git["path"] = "11111"

      argv = %w[harvest-time-entry-data asana]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, "No current/specified task. Did you forget to run `pick`?")
      )
    end
  end

  context "when the task is invalid" do
    it "aborts with correct message" do
      stub_asana_request(global_git, :get, "tasks/00000")
        .with(query: { opt_fields: "name,permalink_url,memberships.project" })
        .to_return(status: 404)

      local_git["path"] = "11111/00000"

      argv = %w[harvest-time-entry-data asana]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid task gid: 00000")
    end
  end

  context "when the project is invalid" do
    it "aborts with correct message" do
      stub_asana_request(global_git, :get, "tasks/33333")
        .with(query: { opt_fields: "name,permalink_url,memberships.project" })
        .to_return(body: Oj.dump({ data: { gid: "33333", memberships: [] } }, mode: :json))

      local_git["path"] = "00000/33333"

      argv = %w[harvest-time-entry-data asana]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, "Invalid or unmatching project gid: 00000")
      )
    end
  end
end
