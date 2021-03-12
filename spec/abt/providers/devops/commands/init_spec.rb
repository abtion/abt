# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Init, :devops) do
  context "when local config is available" do
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: devops_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
    end

    it "prompts for a project and stores it in the configuration" do
      stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards")
        .to_return(body: Oj.dump({ value: [{ id: "abc111", name: "Board 1" },
                                           { id: "abc222", name: "Board 2" }] }, mode: :json))

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[init devops]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== INIT devops =====\n")
      expect(err_output.gets).to include("Please provide the URL for the devops project")

      input.puts("invalid-url")

      expect(err_output.gets).to eq("Invalid URL\n")
      expect(err_output.gets).to include("Please provide the URL for the devops project")

      input.puts("https://dev.azure.com/org-name/project-name")

      expect(err_output.gets).to eq("Select a project work board:\n")
      expect(err_output.gets).to eq("(1) Board 1\n")
      expect(err_output.gets).to eq("(2) Board 2\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("2")

      expect(err_output.gets).to eq("Selected: (2) Board 2\n")
      expect(output.gets).to eq("devops:org-name/project-name/abc222 # Board 2\n")
      expect(err_output.gets).to eq("https://org-name.visualstudio.com/project-name/_boards/board/Board%202\n")

      thr.join

      expect(local_git["path"]).to eq("org-name/project-name/abc222")
    end

    describe "board URL parsing" do
      before do
        stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards")
          .to_return(body: Oj.dump({ value: [{ id: "abc111", name: "Board 1" }] }, mode: :json))
      end

      context("when using dev.azure.com-style url") do
        it "correctly parses the url" do
          output = StringIO.new
          url = "https://dev.azure.com/org-name/project-name"

          allow(Abt::Helpers).to receive(:read_user_input).and_return(url, "1")

          cli = Abt::Cli.new(argv: %w[init devops], err_output: null_stream, output: output)
          cli.perform

          expect(output.string).to eq("devops:org-name/project-name/abc111 # Board 1\n")
          expect(local_git["path"]).to eq("org-name/project-name/abc111")
        end
      end

      context("when using visualstudio.com-style url") do
        it "correctly parses the url" do
          output = StringIO.new
          url = "https://org-name.visualstudio.com/project-name"

          allow(Abt::Helpers).to receive(:read_user_input).and_return(url, "1")

          cli = Abt::Cli.new(argv: %w[init devops], err_output: null_stream, output: output)
          cli.perform

          expect(output.string).to eq("devops:org-name/project-name/abc111 # Board 1\n")
          expect(local_git["path"]).to eq("org-name/project-name/abc111")
        end
      end
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[init devops], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
