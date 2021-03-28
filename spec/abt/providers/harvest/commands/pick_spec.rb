# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Pick, :harvest) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

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

  it "prompts for a task and stores it in the configuration" do
    local_git["path"] = "27701618"

    input = QueueIO.new
    err_output = QueueIO.new
    output = QueueIO.new
    argv = %w[pick harvest]

    thr = Thread.new do
      cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
      allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

      cli.perform
    end

    expect(err_output.gets).to eq("===== PICK harvest =====\n")
    expect(err_output.gets).to eq("Fetching Harvest data...\n")
    expect(err_output.gets).to eq("Select a task from Project:\n")
    expect(err_output.gets).to eq("(1) Task 1\n")
    expect(err_output.gets).to eq("(2) Task 2\n")
    expect(err_output.gets).to eq("(1-2): ")

    input.puts("4")

    expect(err_output.gets).to eq("Invalid selection\n")
    expect(err_output.gets).to eq("(1-2): ")

    input.puts("1")

    expect(err_output.gets).to eq("Selected: (1) Task 1\n")
    expect(output.gets).to eq("harvest:27701618/14628589 # Project > Task 1\n")

    thr.join

    expect(local_git["path"]).to eq("27701618/14628589")
  end

  context "when a project has yet to be selected" do
    it "prompts for a project > task and stores it in the configuration" do
      local_git["path"] = ""

      output = StringIO.new
      err_output = StringIO.new
      argv = %w[pick harvest -c]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      allow(Abt::Helpers).to receive(:read_user_input).and_return("Proj", # Project search
                                                                  "1",    # Project
                                                                  "1")    # Task

      cli.perform

      expect(err_output.string).to include("Select a project")
      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
      expect(local_git["path"]).to eq("27701618/14628589")
    end
  end

  context "when --clean flag added" do
    it "forces a new project to be selected" do
      local_git["path"] = "12323213/234342343"

      output = StringIO.new
      err_output = StringIO.new
      argv = %w[pick harvest -c]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      allow(Abt::Helpers).to receive(:read_user_input).and_return("Proj", # Project search
                                                                  "1",    # Project
                                                                  "1")    # Task

      cli.perform

      expect(err_output.string).to include("Select a project")
      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
      expect(local_git["path"]).to eq("27701618/14628589")
    end
  end

  context "when dry-run" do
    it "doesn't update the configuration" do
      local_git["path"] = "27701618/234342343"

      output = StringIO.new
      argv = %w[pick harvest -d]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1") # Rig the cli to select option 1

      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
      expect(local_git["path"]).to eq("27701618/234342343")
    end
  end

  context "when local config not available" do
    it "works like dry-run" do
      allow(local_git).to receive(:available?).and_return(false)

      output = StringIO.new
      argv = %w[pick harvest:27701618]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)

      # Rig the cli to select option 1 for both section and task
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1", "1")

      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
    end
  end
end
