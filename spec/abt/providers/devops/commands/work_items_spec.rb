# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::WorkItems, :devops) do
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:local_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  it "prints all work items for the board" do
    board_name = "Board"

    stub_devops_request(global_git, "org-name", :get, "project-name/team-name/_apis/work/boards/#{board_name}")
      .to_return(body: Oj.dump({ id: board_name, name: "Board" }, mode: :json))

    wiql = <<~WIQL
      SELECT [System.Id]
      FROM WorkItems
      ORDER BY [System.Title] ASC
    WIQL

    stub_devops_request(global_git, "org-name", :post, "_apis/wit/wiql")
      .with(body: { query: wiql })
      .to_return(body: Oj.dump({ workItems: [{ id: "11111" }, { id: "22222" }] }, mode: :json))

    stub_devops_request(global_git, "org-name", :get, "_apis/wit/workitems")
      .with(query: { ids: "11111,22222" })
      .to_return(body: Oj.dump({ value: [
        { id: "11111", fields: { "System.Title": "Work item A", "System.TeamProject": "project-name" } },
        { id: "22222", fields: { "System.Title": "Work item B", "System.TeamProject": "project-name" } }
      ] }, mode: :json))

    err_output = StringIO.new
    output = StringIO.new
    argv = ["work-items", "devops:org-name/project-name/team-name/#{board_name}"]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== WORK-ITEMS devops:org-name/project-name/team-name/#{board_name} =====
      Fetching work items...
      https://org-name.visualstudio.com/project-name/_workitems/edit/11111
      https://org-name.visualstudio.com/project-name/_workitems/edit/22222
    TXT

    expect(output.string).to eq(<<~TXT)
      devops:org-name/project-name/team-name/#{board_name}/11111 # Work item A
      devops:org-name/project-name/team-name/#{board_name}/22222 # Work item B
    TXT
  end
end
