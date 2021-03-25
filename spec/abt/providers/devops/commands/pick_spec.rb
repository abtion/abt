# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Pick, :devops) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:board_id) { "abc123" }
  let(:board) do
    { id: board_id,
      name: "Board 1",
      columns: [{ name: "WIP" }, { name: "Empty" }] }
  end

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  def stub_boards
    stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards")
      .to_return(body: Oj.dump({ value: [board, { id: "abc222", name: "Board 2", columns: [] }] }, mode: :json))
  end

  def stub_board
    stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards/#{board_id}")
      .to_return(body: Oj.dump(board, mode: :json))
  end

  def stub_wip_column # rubocop:disable Metrics/MethodLength
    wiql = <<~WIQL
      SELECT [System.Id]
      FROM WorkItems
      WHERE [System.BoardColumn] = 'WIP'
      ORDER BY [Microsoft.VSTS.Common.BacklogPriority] ASC
    WIQL

    stub_devops_request(global_git, "org-name", "project-name", :post, "wit/wiql")
      .with(body: { query: wiql })
      .to_return(body: Oj.dump({ workItems: [{ id: "11111" }, { id: "22222" }] }, mode: :json))

    stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
      .with(query: { ids: "11111,22222" })
      .to_return(body: Oj.dump({ value: [
        { id: "11111", fields: { "System.Title": "Work Item A" } },
        { id: "22222", fields: { "System.Title": "Work Item B" } }
      ] }, mode: :json))
  end

  def stub_empty_column
    wiql = <<~WIQL
      SELECT [System.Id]
      FROM WorkItems
      WHERE [System.BoardColumn] = 'Empty'
      ORDER BY [Microsoft.VSTS.Common.BacklogPriority] ASC
    WIQL

    stub_devops_request(global_git, "org-name", "project-name", :post, "wit/wiql")
      .with(body: { query: wiql })
      .to_return(body: Oj.dump({ workItems: [] }, mode: :json))
  end

  it "prompts for a work item on the board and stores it in the configuration" do
    stub_board
    stub_wip_column
    stub_empty_column

    local_git["path"] = "org-name/project-name/#{board_id}"

    input = QueueIO.new
    err_output = QueueIO.new
    output = QueueIO.new
    argv = %w[pick devops]

    thr = Thread.new do
      cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
      allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

      cli.perform
    end

    expect(err_output.gets).to eq("===== PICK devops =====\n")
    expect(err_output.gets).to eq("Which column in Board 1?:\n")
    expect(err_output.gets).to eq("(1) WIP\n")
    expect(err_output.gets).to eq("(2) Empty\n")
    expect(err_output.gets).to eq("(1-2): ")

    input.puts("2")

    expect(err_output.gets).to eq("Selected: (2) Empty\n")
    expect(err_output.gets).to eq("Fetching work items...\n")
    expect(err_output.gets).to eq("Section is empty\n")

    expect(err_output.gets).to eq("Which column in Board 1?:\n")
    expect(err_output.gets).to eq("(1) WIP\n")
    expect(err_output.gets).to eq("(2) Empty\n")
    expect(err_output.gets).to eq("(1-2): ")

    input.puts("1")

    expect(err_output.gets).to eq("Selected: (1) WIP\n")
    expect(err_output.gets).to eq("Fetching work items...\n")
    expect(err_output.gets).to eq("Select a work item:\n")
    expect(err_output.gets).to eq("(1) #11111 Work Item A\n")
    expect(err_output.gets).to eq("(2) #22222 Work Item B\n")
    expect(err_output.gets).to eq("(1-2, q: back): ")

    input.puts("q")

    expect(err_output.gets).to eq("Which column in Board 1?:\n")
    expect(err_output.gets).to eq("(1) WIP\n")
    expect(err_output.gets).to eq("(2) Empty\n")
    expect(err_output.gets).to eq("(1-2): ")

    input.puts("1")

    expect(err_output.gets).to eq("Selected: (1) WIP\n")
    expect(err_output.gets).to eq("Fetching work items...\n")
    expect(err_output.gets).to eq("Select a work item:\n")
    expect(err_output.gets).to eq("(1) #11111 Work Item A\n")
    expect(err_output.gets).to eq("(2) #22222 Work Item B\n")
    expect(err_output.gets).to eq("(1-2, q: back): ")

    input.puts("1")

    expect(err_output.gets).to eq("Selected: (1) #11111 Work Item A\n")
    expect(output.gets).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
    expect(err_output.gets).to eq("https://org-name.visualstudio.com/project-name/_workitems/edit/11111\n")

    thr.join

    expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/11111")
  end

  context "when no board has been selected" do
    it "prompts for a board and then the work item" do
      stub_boards
      stub_board
      stub_wip_column
      stub_empty_column

      local_git["path"] = ""

      output = StringIO.new
      err_output = StringIO.new
      argv = %w[pick devops -c]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      allow(Abt::Helpers).to receive(:read_user_input).and_return("https://dev.azure.com/org-name/project-name",
                                                                  "1", # Board
                                                                  "1", # Column
                                                                  "1") # Work item

      cli.perform

      expect(err_output.string).to include("Please provide the URL for the devops project")
      expect(output.string).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
      expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/11111")
    end
  end

  context "when --clean flag added" do
    it "forces a board to be selected even though one was already set" do
      stub_boards
      stub_board
      stub_wip_column
      stub_empty_column

      local_git["path"] = "org-name/project-name/#{board_id}"

      output = StringIO.new
      err_output = StringIO.new
      argv = %w[pick devops -c]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      allow(Abt::Helpers).to receive(:read_user_input).and_return("https://dev.azure.com/org-name/project-name",
                                                                  "1", # Board
                                                                  "1", # Column
                                                                  "1") # Work item

      cli.perform

      expect(err_output.string).to include("Please provide the URL for the devops project")
      expect(output.string).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
      expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/11111")
    end
  end

  context "when dry-run" do
    it "doesn't update the configuration" do
      stub_board
      stub_wip_column
      stub_empty_column

      local_git["path"] = "org-name/project-name/#{board_id}/00000"

      output = StringIO.new
      argv = %w[pick devops -d]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)

      # Rig the cli to select option 1 for both column and work item
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1", "1")

      cli.perform

      expect(output.string).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
      expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/00000")
    end
  end

  context "when local config not available" do
    it "works like dry-run" do
      stub_board
      stub_wip_column
      stub_empty_column

      allow(local_git).to receive(:available?).and_return(false)

      output = StringIO.new
      argv = ["pick", "devops:org-name/project-name/#{board_id}/00000"]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)

      # Rig the cli to select option 1 for both section and task
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1", "1")

      cli.perform

      expect(output.string).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
    end
  end
end
