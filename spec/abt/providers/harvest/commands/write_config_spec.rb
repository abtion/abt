# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::WriteConfig, :harvest, :directory_config) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

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
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)

    stub_get_project_assignments(global_git, [
      {
        project: { id: 27_701_618, name: "Project" },
        client: { name: "Abtion" },
        task_assignments: [
          { task: { id: 14_628_589, name: "Task 1" } },
          { task: { id: 14_628_590, name: "Task 2" } }
        ]
      }
    ])
  end

  it "stores the project/task configuration to the repo's .abt.yml" do
    local_git["path"] = "11111/44444"

    err_output = StringIO.new
    argv = %w[write-config harvest]
    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_stream)
    cli.perform

    abt_file = File.open(".abt.yml")
    expect(err_output.string).to include("Harvest configuration written to .abt.yml")
    expect(abt_file.read).to eq(<<~YML)
      ---
      harvest:
        path: 11111/44444
    YML
  end

  context "when using --clean flag" do
    it "prompts for project and task" do
      local_git["path"] = "11111/44444"

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config harvest -c]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG harvest -c =====\n")
      expect(err_output.gets).to eq("Fetching Harvest data...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Abt")

      expect(err_output.gets).to eq("Select a match:\n")
      expect(err_output.gets).to eq("(1) Abtion > Project\n")
      expect(err_output.gets).to eq("(1, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Abtion > Project\n")

      expect(err_output.gets).to eq("Select a task from Project:\n")
      expect(err_output.gets).to eq("(1) Task 1\n")
      expect(err_output.gets).to eq("(2) Task 2\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Task 1\n")
      expect(err_output.gets).to eq("Harvest configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        harvest:
          path: 27701618/14628589
      YML
    end
  end

  context "when a project has not yet been selected" do
    it "prompts for project" do
      local_git["path"] = ""

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[write-config harvest]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== WRITE-CONFIG harvest =====\n")
      expect(err_output.gets).to eq("Fetching Harvest data...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq("Enter search: ")

      input.puts("Abt")

      expect(err_output.gets).to eq("Select a match:\n")
      expect(err_output.gets).to eq("(1) Abtion > Project\n")
      expect(err_output.gets).to eq("(1, q: back): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Abtion > Project\n")

      expect(err_output.gets).to eq("Select a task from Project:\n")
      expect(err_output.gets).to eq("(1) Task 1\n")
      expect(err_output.gets).to eq("(2) Task 2\n")
      expect(err_output.gets).to eq("(1-2): ")

      input.puts("1")

      expect(err_output.gets).to eq("Selected: (1) Task 1\n")
      expect(err_output.gets).to eq("Harvest configuration written to .abt.yml\n")

      thr.join

      abt_file = File.open(".abt.yml")
      expect(abt_file.read).to eq(<<~YML)
        ---
        harvest:
          path: 27701618/14628589
      YML
    end
  end
end
