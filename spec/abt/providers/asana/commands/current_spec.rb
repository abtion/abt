# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Current, :asana) do
  context "when local config is available" do
    let(:asana_credentials) { { "accessToken" => "access_token" } }
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: asana_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

      stub_asana_request(global_git, :get, "projects/11111")
        .with(query: { opt_fields: "name,permalink_url" })
        .to_return(body: Oj.dump(
          { data: { gid: "11111", name: "Project",
                    permalink_url: "https://proj.ect/11111/URL" } }, mode: :json
        ))

      stub_asana_request(global_git, :get, "tasks/22222")
        .with(query: { opt_fields: "name,permalink_url" })
        .to_return(body: Oj.dump(
          { data: { gid: "22222", name: "Task",
                    permalink_url: "https://ta.sk/22222/URL" } }, mode: :json
        ))
    end

    it "prints the current ARI with task title" do
      local_git["path"] = "11111/22222"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[current asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== CURRENT asana =====
        Fetching project...
        Fetching task...
        https://ta.sk/22222/URL
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:11111/22222 # Task
      TXT
    end

    context "when ARI doesn't include a task" do
      it "prints the current ARI with project title." do
        local_git["path"] = "11111"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current asana]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to eq(<<~TXT)
          ===== CURRENT asana =====
          Fetching project...
          https://proj.ect/11111/URL
        TXT

        expect(output.string).to eq(<<~TXT)
          asana:11111 # Project
        TXT
      end
    end

    context "when provided a path" do
      it "overrides the configuration" do
        local_git["path"] = "00000/00000"

        err_output = StringIO.new
        output = StringIO.new
        argv = ["current", "asana:11111/22222"]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to include("Configuration updated")
        expect(local_git["path"]).to eq("11111/22222")
      end
    end

    context "when the project is invalid" do
      it 'aborts with "Invalid project"' do
        stub_asana_request(global_git, :get, "projects/00000")
          .with(query: { opt_fields: "name,permalink_url" })
          .to_return(status: 404)

        local_git["path"] = "00000/22222"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current asana]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid project: 00000")
      end
    end

    context "when the task is invalid" do
      it 'aborts with "Invalid project"' do
        stub_asana_request(global_git, :get, "tasks/00000")
          .with(query: { opt_fields: "name,permalink_url" })
          .to_return(status: 404)

        local_git["path"] = "11111/00000"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current asana]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid task: 00000")
      end
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[current asana], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
