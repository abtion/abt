# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::WriteConfig, :devops, :directory_config) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:board_name) { "board" }
  let(:board) do
    { name: board_name, columns: [{ name: "WIP" }, { name: "Empty" }] }
  end

  around do |example|
    # Run each example inside a fresh git repo
    Dir.mktmpdir do |git_root|
      Open3.popen3("git init #{git_root}") do |_i, _o, _e, thread|
        thread.join
      end

      Dir.chdir(git_root) do
        example.call
      end
    end
  end

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)

    stub_devops_request(global_git, "org-name", :get, "_apis/projects/project-name/teams")
      .to_return(body: Oj.dump({ value: [{ name: "team-name" }] }, mode: :json))

    stub_devops_request(global_git, "org-name", :get, "project-name/team-name/_apis/work/boards")
      .to_return(body: Oj.dump({ value: [board, { id: "abc222", name: "Board 2", columns: [] }] }, mode: :json))

    stub_devops_request(global_git, "org-name", :get, "project-name/team-name/_apis/work/boards/#{board_name}")
      .to_return(body: Oj.dump(board, mode: :json))
  end

  it "stores the board configuration to the repo's .abt.yml" do
    local_git["path"] = "org-name/project-name/team-name/#{board_name}/34234"

    err_output = StringIO.new
    argv = %w[write-config devops]
    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_stream)
    cli.perform

    abt_file = File.open(".abt.yml")
    expect(err_output.string).to include("DevOps configuration written to .abt.yml")
    expect(abt_file.read).to eq(<<~YML)
      ---
      devops:
        path: org-name/project-name/team-name/#{board_name}
    YML
  end

  context "when using --clean flag" do
    it "prompts for instance, project, team and board" do
      local_git["path"] = "other-org-name/other-project-name/other-team-name/12345"

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config devops -c]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG devops -c =====\n")
      expect(err_output.gets).to include("Enter URL")

      input.puts("https://dev.azure.com/org-name/project-name")

      expect(err_output.gets).to eq("Select a team:\n")
      expect(err_output.gets).to eq("(1) team-name\n")
      expect(err_output.gets).to eq("(1): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) team-name\n")

      expect(err_output.gets).to eq("Select a project work board:\n")
      expect(err_output.gets).to eq("(1) #{board_name}\n")
      expect(err_output.gets).to eq("(2) Board 2\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) #{board_name}\n")
      expect(err_output.gets).to eq("DevOps configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        devops:
          path: org-name/project-name/team-name/#{board_name}
      YML
    end
  end

  context "when a project has not yet been selected" do
    it "prompts for project" do
      local_git["path"] = ""

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config devops]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG devops =====\n")
      expect(err_output.gets).to include("Enter URL")

      input.puts("https://dev.azure.com/org-name/project-name")

      expect(err_output.gets).to eq("Select a team:\n")
      expect(err_output.gets).to eq("(1) team-name\n")
      expect(err_output.gets).to eq("(1): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) team-name\n")

      expect(err_output.gets).to eq("Select a project work board:\n")
      expect(err_output.gets).to eq("(1) #{board_name}\n")
      expect(err_output.gets).to eq("(2) Board 2\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) #{board_name}\n")
      expect(err_output.gets).to eq("DevOps configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        devops:
          path: org-name/project-name/team-name/#{board_name}
      YML
    end
  end
end
