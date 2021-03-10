# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Init, :asana) do
  context "when local config is available" do
    let(:asana_credentials) do
      { "accessToken" => "access_token", "workspaceGid" => "workspace_gid" }
    end
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: asana_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

      expected_query = {
        workspace: global_git["workspaceGid"],
        archived: false,
        opt_fields: "name,permalink_url"
      }

      stub_get_projects(global_git, expected_query, [
        {
          gid: "11111",
          name: "Project 1",
          permalink_url: "https://proj.ect/11111/URL"
        },
        {
          gid: "22222",
          name: "Project 2",
          permalink_url: "https://proj.ect/22222/URL"
        }
      ])
    end

    it "prompts for a project and stores it in the configuration" do
      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[init asana]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== INIT asana =====\n")
      expect(err_output.gets).to eq("Fetching projects...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Search that does not match anything")

      expect(err_output.gets).to eq("No matches\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Proj")

      expect(err_output.gets).to eq("Select a project:\n")
      expect(err_output.gets).to eq("(1) Project 1\n")
      expect(err_output.gets).to eq("(2) Project 2\n")
      expect(err_output.gets).to eq("(1-2, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Project 1\n")
      expect(output.gets).to eq("asana:11111 # Project 1\n")
      expect(err_output.gets).to eq("https://proj.ect/11111/URL\n")

      thr.join

      expect(local_git["path"]).to eq("11111")
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[init asana], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
