# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Init, :harvest) do
  context "when local config is available" do
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)

      stub_get_project_assignments(global_git, [
        {
          project: { id: 27_701_618, name: "Project" },
          client: { name: "Abtion" }
        }
      ])
    end

    it "prompts for a project and stores it in the configuration" do
      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[init harvest]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== INIT harvest =====\n")
      expect(err_output.gets).to eq("Fetching projects...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Search that does not match anything")

      expect(err_output.gets).to eq("No matches\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Proj")

      expect(err_output.gets).to eq("Select a match:\n")
      expect(err_output.gets).to eq("(1) Abtion > Project\n")
      expect(err_output.gets).to eq("(1, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Abtion > Project\n")
      expect(output.gets).to eq("harvest:27701618 # Abtion > Project\n")

      thr.join

      expect(local_git["path"]).to eq("27701618")
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[init harvest], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
