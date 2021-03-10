# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::BranchName, :asana) do
  let(:asana_credentials) { { "accessToken" => "access_token" } }
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

    stub_asana_request(global_git, :get, "tasks/22222")
      .with(query: { opt_fields: "name,memberships.project" })
      .to_return(body: Oj.dump({ data: { gid: "22222",
                                         name: "A long task \#$\#$ name",
                                         memberships: [{ project: { gid: "11111" } }] } },
                               mode: :json))
  end

  it "prints a git branch name suggestion for the task" do
    local_git["path"] = "11111/22222"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[branch-name asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== BRANCH-NAME asana =====
      Fetching task...
    TXT

    expect(output.string).to eq(<<~TXT)
      a-long-task-name
    TXT
  end

  context "when ARI doesn't include a task" do
    it "aborts with correct message" do
      local_git["path"] = "11111"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, "No current/specified task. Did you pick an Asana task?")
      )
    end
  end

  context "when the task is invalid" do
    it "aborts with correct message" do
      stub_asana_request(global_git, :get, "tasks/00000")
        .with(query: { opt_fields: "name,memberships.project" })
        .to_return(status: 404)

      local_git["path"] = "11111/00000"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid task gid: 00000")
    end
  end

  context "when the project is invalid" do
    it "aborts with correct message" do
      stub_asana_request(global_git, :get, "tasks/33333")
        .with(query: { opt_fields: "name,memberships.project" })
        .to_return(body: Oj.dump({ data: { gid: "33333", memberships: [] } }, mode: :json))

      local_git["path"] = "00000/33333"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, "Invalid or unmatching project gid: 00000")
      )
    end
  end
end
