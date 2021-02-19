# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Add, :asana) do
  let(:asana_credentials) { { 'accessToken' => 'access_token', 'workspaceGid' => 'workspace_gid' } }
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.asana').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.asana').and_return(global_git)

    stub_get_project(global_git, { opt_fields: 'name' }, gid: '11111', name: 'Project')
    stub_get_sections(global_git, { opt_fields: 'name' }, '11111', [
                        { gid: '22222', name: 'Section A' },
                        { gid: '33333', name: 'Section B' }
                      ])
  end

  def stub_post_task(git_config, task)
    stub_request(:post, 'https://app.asana.com/api/1.0/tasks')
      .with(headers: request_headers_for_git_config(git_config))
      .to_return(body: Oj.dump({ data: task }, mode: :json))
  end

  it 'prompts for title, description and section and adds a task' do
    stub_post_task(global_git, gid: '44444', name: 'A task')
      .with(body: { data: { name: 'A task', notes: 'Notes', projects: ['11111'] } })

    # This request will only be performed if the user decides to add the task to a section
    stub_request(:post, 'https://app.asana.com/api/1.0/sections/22222/addTask')
      .with(headers: request_headers_for_git_config(global_git))
      .with(body: { data: { task: '44444' } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))

    input = QueueIO.new
    err_output = QueueIO.new
    output = QueueIO.new
    argv = %w[add asana:11111]

    thr = Thread.new do
      cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
      allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

      cli.perform
    end

    expect(err_output.gets).to eq("===== ADD asana:11111 =====\n")
    expect(err_output.gets).to eq('Enter task description: ')

    input.puts('A task')

    expect(err_output.gets).to eq('Enter task notes: ')

    input.puts('Notes')

    expect(err_output.gets).to eq("Task created\n")
    expect(err_output.gets).to eq("Fetching sections...\n")
    expect(err_output.gets).to eq("Add to section?:\n")
    expect(err_output.gets).to eq("(1) Section A\n")
    expect(err_output.gets).to eq("(2) Section B\n")
    expect(err_output.gets).to eq('(1-2, q: Don\'t add to section): ')

    input.puts('1')

    expect(output.gets).to eq("asana:11111/44444 # A task\n")

    thr.join
  end

  context 'when no path current/specified project' do
    it 'aborts with correct error message' do
      argv = %w[add asana]
      cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, 'No current/specified project. Did you initialize Asana?')
      )
    end
  end
end
