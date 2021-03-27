# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::WriteConfig, :asana, :directory_config) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

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
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)

    expected_query = {
      workspace: global_git["workspaceGid"],
      archived: false,
      opt_fields: "name,permalink_url"
    }

    stub_get_projects(global_git, expected_query, [
      { gid: "11111",
        name: "Project 1",
        permalink_url: "https://proj.ect/11111/URL" },
      { gid: "22222",
        name: "Project 2",
        permalink_url: "https://proj.ect/22222/URL" }
    ])

    stub_asana_request(global_git, :get, "projects/11111/sections")
      .with(query: { limit: 100, opt_fields: "name" })
      .to_return(body: Oj.dump({ data: [
        { gid: "22222", name: "WIP" },
        { gid: "33333", name: "Finalized" }
      ] }, mode: :json))
  end

  it "stores the project configuration to the repo's .abt.yml" do
    local_git["path"] = "11111/44444"
    local_git["wipSectionGid"] = "22222"
    local_git["finalizedSectionGid"] = "33333"

    err_output = StringIO.new
    argv = %w[write-config asana]
    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_stream)
    cli.perform

    abt_file = File.open(".abt.yml")
    expect(err_output.string).to include("Asana configuration written to .abt.yml")
    expect(abt_file.read).to eq(<<~YML)
      ---
      asana:
        path: '11111'
        wip_section_gid: '22222'
        finalized_section_gid: '33333'
    YML
  end

  context "when using --clean flag" do
    it "prompts for project" do
      local_git["path"] = "11111/44444"
      local_git["wipSectionGid"] = "22222"
      local_git["finalizedSectionGid"] = "33333"

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config asana -c]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG asana -c =====\n")
      expect(err_output.gets).to eq("Fetching projects...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Project 1")

      expect(err_output.gets).to eq("Select a match:\n")
      expect(err_output.gets).to eq("(1) Project 1\n")
      expect(err_output.gets).to eq("(1, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Project 1\n")
      expect(err_output.gets).to eq("Asana configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        asana:
          path: '11111'
          wip_section_gid: '22222'
          finalized_section_gid: '33333'
      YML
    end
  end

  context "when a project has not yet been selected" do
    it "prompts for project" do
      local_git["path"] = ""

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config asana -c]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG asana -c =====\n")
      expect(err_output.gets).to eq("Fetching projects...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Project 1")

      expect(err_output.gets).to eq("Select a match:\n")
      expect(err_output.gets).to eq("(1) Project 1\n")
      expect(err_output.gets).to eq("(1, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Project 1\n")

      expect(err_output.gets).to eq("Fetching sections...\n")

      expect(err_output.gets).to eq("Select WIP (Work In Progress) section:\n")
      expect(err_output.gets).to eq("(1) WIP\n")
      expect(err_output.gets).to eq("(2) Finalized\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) WIP\n")

      expect(err_output.gets).to eq("Select section for finalized tasks (E.g. \"Merged\"):\n")
      expect(err_output.gets).to eq("(1) WIP\n")
      expect(err_output.gets).to eq("(2) Finalized\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("2")

      expect(err_output.gets).to eq("Selected: (2) Finalized\n")
      expect(err_output.gets).to eq("Asana configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        asana:
          path: '11111'
          wip_section_gid: '22222'
          finalized_section_gid: '33333'
      YML
    end
  end
end
