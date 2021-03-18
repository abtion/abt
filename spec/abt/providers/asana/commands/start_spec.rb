# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Start, :asana) do
  let(:local_git) { GitConfigMock.new(data: { "wipSectionGid" => wip_section_id }) }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  let(:user_id) { "1001" }
  let(:project_id) { "1002" }
  let(:wip_section_id) { "1003" }
  let(:task_id) { "1004" }

  def stub_user_request
    stub_asana_request(global_git, :get, "users/me")
      .with(query: { opt_fields: "name" })
      .to_return(body: Oj.dump({ data: { gid: user_id, name: "Name of user" } }, mode: :json))
  end

  def stub_project_request
    stub_asana_request(global_git, :get, "projects/#{project_id}")
      .with(query: { opt_fields: "name" })
      .to_return(body: Oj.dump({ data: { gid: project_id, name: "Project" } }, mode: :json))
  end

  def stub_task_request
    stub_asana_request(global_git, :get, "tasks/#{task_id}")
      .with(query: { opt_fields: "name,memberships.section.name,assignee.name,permalink_url" })
      .to_return(body: Oj.dump({ data: { gid: task_id,
                                         name: "Started task",
                                         assignee: nil,
                                         memberships: [],
                                         permalink_url: "https://ta.sk/#{task_id}/URL" } },
                               mode: :json))
  end

  def stub_wip_section_request
    stub_asana_request(global_git, :get, "sections/#{wip_section_id}")
      .with(query: { opt_fields: "name" })
      .to_return(body: Oj.dump({ data: { gid: wip_section_id, name: "WIP" } }, mode: :json))
  end

  def stub_add_to_wip_section_request
    stub_asana_request(global_git, :post, "sections/#{wip_section_id}/addTask")
      .with(body: { data: { task: task_id } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))
  end

  def stub_reassign_request
    stub_asana_request(global_git, :put, "tasks/#{task_id}")
      .with(body: { data: { assignee: user_id } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))
  end

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)
  end

  it "assigns the current user to the current task and moves the task to the wip-section" do
    stub_user_request
    stub_project_request
    stub_task_request
    stub_wip_section_request
    stub_add_to_wip_section_request
    stub_reassign_request

    local_git["path"] = "#{project_id}/#{task_id}"
    err_output = StringIO.new
    output = StringIO.new
    argv = %w[start asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== START asana =====
      https://ta.sk/#{task_id}/URL
      Assigning task to user: Name of user
      Moving task to section: WIP
    TXT

    expect(output.string).to eq(<<~TXT)
      asana:#{project_id}/#{task_id} # Started task
    TXT
  end

  context "when the task is already in the WIP section" do
    it "does not move the task" do
      stub_user_request
      stub_project_request
      stub_wip_section_request
      stub_reassign_request

      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: "name,memberships.section.name,assignee.name,permalink_url" })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: "Started task",
                                           assignee: nil,
                                           memberships: [{ section: { gid: wip_section_id,
                                                                      name: "WIP" } }],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      local_git["path"] = "#{project_id}/#{task_id}"
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== START asana =====
        https://ta.sk/#{task_id}/URL
        Assigning task to user: Name of user
        Task already in section: WIP
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:#{project_id}/#{task_id} # Started task
      TXT
    end
  end

  context "when the task is already assigned to the current user" do
    it "does not reassign the task" do
      stub_user_request
      stub_project_request
      stub_wip_section_request
      stub_add_to_wip_section_request

      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: "name,memberships.section.name,assignee.name,permalink_url" })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: "Started task",
                                           assignee: { gid: user_id },
                                           memberships: [],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      local_git["path"] = "#{project_id}/#{task_id}"
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== START asana =====
        https://ta.sk/#{task_id}/URL
        You are already assigned to this task
        Moving task to section: WIP
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:#{project_id}/#{task_id} # Started task
      TXT
    end
  end

  context "when the task is assigned to another user" do
    it "lets the user decide whether or not to reassign it" do
      stub_user_request
      stub_project_request
      stub_wip_section_request
      stub_add_to_wip_section_request
      stub_reassign_request

      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: "name,memberships.section.name,assignee.name,permalink_url" })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: "Started task",
                                           assignee: { gid: "4234", name: "Another assigned user" },
                                           memberships: [],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      local_git["path"] = "#{project_id}/#{task_id}"

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[start asana]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== START asana =====\n")
      expect(err_output.gets).to eq("https://ta.sk/#{task_id}/URL\n")
      expect(err_output.gets).to eq("Task is assigned to: Another assigned user, take over? (y/n): ")

      input.puts("y")

      expect(err_output.gets).to eq("Reassigning task to user: Name of user\n")
      expect(err_output.gets).to eq("Moving task to section: WIP\n")
      expect(output.gets).to eq("asana:#{project_id}/#{task_id} # Started task\n")

      thr.join
    end
  end

  context "when using --set flag" do
    it "overrides the current task" do
      stub_user_request
      stub_project_request
      stub_task_request
      stub_wip_section_request
      stub_add_to_wip_section_request
      stub_reassign_request

      other_task_id = "32432432432"
      local_git["path"] = "#{project_id}/#{other_task_id}"
      err_output = StringIO.new
      output = StringIO.new
      argv = ["start", "asana:#{project_id}/#{task_id}", "-s"]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== START asana:#{project_id}/#{task_id} -s =====
        https://ta.sk/#{task_id}/URL
        Assigning task to user: Name of user
        Moving task to section: WIP
        Current task updated
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:#{project_id}/#{task_id} # Started task
      TXT

      expect(local_git["path"]).to eq("#{project_id}/#{task_id}")
    end
  end

  context "when task is outside of current project" do
    it "does not move the task - since the WIP section is stored per git repo" do
      stub_user_request
      stub_project_request
      stub_reassign_request

      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: "name,memberships.section.name,assignee.name,permalink_url" })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: "Task outside of current project",
                                           assignee: nil,
                                           memberships: [],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      other_project_id = "32432432432"
      local_git["path"] = other_project_id
      err_output = StringIO.new
      output = StringIO.new
      argv = ["start", "asana:#{project_id}/#{task_id}"]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== START asana:#{project_id}/#{task_id} =====
        https://ta.sk/#{task_id}/URL
        Assigning task to user: Name of user
        Task was not moved, this is not implemented for tasks outside current project
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:#{project_id}/#{task_id} # Task outside of current project
      TXT
    end
  end

  context "when no current/specified task" do
    it "aborts with correct error message" do
      argv = %w[start asana]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort,
                    "No current/specified project. Did you initialize Asana and pick a task?")
      )
    end
  end
end
