# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Current, :devops) do
  context "when local config is available" do
    let(:devops_credentials) do
      { "organizations.org-name.username" => "username",
        "organizations.org-name.accessToken" => "accessToken" }
    end
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: devops_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)

      stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards/11111")
        .to_return(body: Oj.dump({ id: "11111", name: "Board" }, mode: :json))

      stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
        .with(query: { ids: "22222" })
        .to_return(body: Oj.dump({ value: [{ id: 22_222,
                                             fields: { 'System.Title': "Work Item" } }] },
                                 mode: :json))
    end

    it "prints the current ARI with work item title" do
      local_git["path"] = "org-name/project-name/11111/22222"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[current devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== CURRENT devops =====
        Fetching board...
        Fetching work item...
        https://org-name.visualstudio.com/project-name/_workitems/edit/22222
      TXT

      expect(output.string).to eq(<<~TXT)
        devops:org-name/project-name/11111/22222 # Work Item
      TXT
    end

    context "when ARI doesn't include a work item" do
      it "prints the current ARI with board title." do
        local_git["path"] = "org-name/project-name/11111"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current devops]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to eq(<<~TXT)
          ===== CURRENT devops =====
          Fetching board...
          https://org-name.visualstudio.com/project-name/_boards/board/Board
        TXT

        expect(output.string).to eq(<<~TXT)
          devops:org-name/project-name/11111 # Board
        TXT
      end
    end

    context "when provided a path" do
      it "overrides the configuration" do
        local_git["path"] = "org-name/project-name/00000/99999"

        err_output = StringIO.new
        output = StringIO.new
        argv = ["current", "devops:org-name/project-name/11111/22222"]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to include("Configuration updated")
        expect(local_git["path"]).to eq("org-name/project-name/11111/22222")
      end
    end

    context "when the board is invalid" do
      it 'aborts with "Invalid board"' do
        stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards/00000")
          .to_return(status: 404)

        local_git["path"] = "org-name/project-name/00000/22222"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current devops]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect do
          cli.perform
        end.to raise_error(
          Abt::Cli::Abort,
          "Board could not be found, ensure that settings for organization, project, and board are correct"
        )
      end
    end

    context "when the work_item is invalid" do
      it 'aborts with "Invalid project"' do
        stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
          .with(query: { ids: "00000" })
          .to_return(status: 404) # The DevOps API sends a 404 rather than an empty list

        local_git["path"] = "org-name/project-name/11111/00000"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current devops]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, "No such work item: #00000")
      end
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[current devops], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
