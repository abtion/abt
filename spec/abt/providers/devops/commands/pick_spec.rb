# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Pick, :devops) do
  context "when local config is available" do
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: devops_credentials) }
    let(:board_id) { "abc123" }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
    end

    def stub_board
      stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards/#{board_id}")
        .to_return(body: Oj.dump({ id: board_id,
                                   name: "Board",
                                   columns: [{ name: "WIP" }, { name: "Empty" }] },
                                 mode: :json))
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

    it "prompts for a work item and stores it in the configuration" do
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
      expect(err_output.gets).to eq("project-name - Board\n")
      expect(err_output.gets).to eq("Which column?:\n")
      expect(err_output.gets).to eq("(1) WIP\n")
      expect(err_output.gets).to eq("(2) Empty\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("2")

      expect(err_output.gets).to eq("Selected: (2) Empty\n")
      expect(err_output.gets).to eq("Fetching work items...\n")
      expect(err_output.gets).to eq("Section is empty\n")

      expect(err_output.gets).to eq("Which column?:\n")
      expect(err_output.gets).to eq("(1) WIP\n")
      expect(err_output.gets).to eq("(2) Empty\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) WIP\n")
      expect(err_output.gets).to eq("Fetching work items...\n")
      expect(err_output.gets).to eq("Select a work item:\n")
      expect(err_output.gets).to eq("(1) Work Item A\n")
      expect(err_output.gets).to eq("(2) Work Item B\n")
      expect(err_output.gets).to eq("(1-2, q: back): ")

      input.puts("q")

      expect(err_output.gets).to eq("Which column?:\n")
      expect(err_output.gets).to eq("(1) WIP\n")
      expect(err_output.gets).to eq("(2) Empty\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) WIP\n")
      expect(err_output.gets).to eq("Fetching work items...\n")
      expect(err_output.gets).to eq("Select a work item:\n")
      expect(err_output.gets).to eq("(1) Work Item A\n")
      expect(err_output.gets).to eq("(2) Work Item B\n")
      expect(err_output.gets).to eq("(1-2, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Work Item A\n")
      expect(output.gets).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
      expect(err_output.gets).to eq("https://org-name.visualstudio.com/project-name/_workitems/edit/11111\n")

      thr.join

      expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/11111")
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

        # Rig the cli to select option 1 for both section and task
        allow(Abt::Helpers).to receive(:read_user_input).and_return("1", "1")

        cli.perform

        expect(output.string).to eq("devops:org-name/project-name/#{board_id}/11111 # Work Item A\n")
        expect(local_git["path"]).to eq("org-name/project-name/#{board_id}/00000")
      end
    end

    context "when no board has been selected yet" do
      it "aborts with correct message" do
        cli = Abt::Cli.new(argv: %w[pick devops], input: null_tty, output: null_stream)

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort,
                           "No current/specified board. Did you initialize DevOps?")
      end
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[pick devops], input: null_tty, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
