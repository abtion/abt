# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Projects, :asana) do
  let(:asana_credentials) { { "accessToken" => "access_token", "workspaceGid" => "workspace_gid" } }
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

    expected_query = {
      workspace: global_git["workspaceGid"],
      archived: false,
      opt_fields: "name"
    }

    stub_get_projects(global_git, expected_query, [
      {
        gid: "11111",
        name: "Project 1"
      },
      {
        gid: "22222",
        name: "Project 2"
      }
    ])
  end

  it "prints all projects" do
    err_output = StringIO.new
    output = StringIO.new
    argv = %w[projects asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== PROJECTS asana =====
      Fetching projects...
    TXT

    expect(output.string).to eq(<<~TXT)
      asana:11111 # Project 1
      asana:22222 # Project 2
    TXT
  end
end
