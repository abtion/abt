# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::WorkItems, :devops) do
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:local_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  context "when board specified" do
    it "prints all work items for the board" do
      board_id = "11111"

      stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards/#{board_id}")
        .to_return(body: Oj.dump({ id: board_id, name: "Board" }, mode: :json))

      wiql = <<~WIQL
        SELECT [System.Id]
        FROM WorkItems
        ORDER BY [System.Title] ASC
      WIQL

      stub_devops_request(global_git, "org-name", "project-name", :post, "wit/wiql")
        .with(body: { query: wiql })
        .to_return(body: Oj.dump({ workItems: [{ id: "11111" }, { id: "22222" }] }, mode: :json))

      stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
        .with(query: { ids: "11111,22222" })
        .to_return(body: Oj.dump({ value: [
          { id: "11111", fields: { "System.Title": "Work item A" } },
          { id: "22222", fields: { "System.Title": "Work item B" } }
        ] }, mode: :json))

      err_output = StringIO.new
      output = StringIO.new
      argv = ["work-items", "devops:org-name/project-name/#{board_id}"]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== WORK-ITEMS devops:org-name/project-name/#{board_id} =====
        Fetching work items...
        https://org-name.visualstudio.com/project-name/_workitems/edit/11111
        https://org-name.visualstudio.com/project-name/_workitems/edit/22222
      TXT

      expect(output.string).to eq(<<~TXT)
        devops:org-name/project-name/#{board_id}/11111 # Work item A
        devops:org-name/project-name/#{board_id}/22222 # Work item B
      TXT
    end
  end

  context "when no board specified" do
    it "aborts with correct message" do
      cli = Abt::Cli.new(argv: %w[work-items devops], input: null_tty, output: null_stream)

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort,
                         "No current/specified board. Did you initialize DevOps?")
    end
  end
end
