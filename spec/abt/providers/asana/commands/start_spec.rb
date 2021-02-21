# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Start, :asana) do
  let(:asana_credentials) do
    {
      'accessToken' => 'access_token',
      'workspaceGid' => 'workspace_gid'
    }
  end
  let(:local_git) { GitConfigMock.new(data: { 'wipSectionGid' => '33333' }) }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.asana').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.asana').and_return(global_git)

    stub_asana_request(global_git, :get, 'users/me')
      .with(query: { opt_fields: 'name' })
      .to_return(body: Oj.dump({ data: { gid: '88888', name: 'Name of user' } }, mode: :json))

    stub_asana_request(global_git, :get, 'projects/11111')
      .with(query: { opt_fields: 'name' })
      .to_return(body: Oj.dump({ data: { gid: '11111', name: 'Project' } }, mode: :json))

    stub_asana_request(global_git, :get, 'sections/33333')
      .with(query: { opt_fields: 'name' })
      .to_return(body: Oj.dump({ data: { gid: '33333', name: 'WIP' } }, mode: :json))

    stub_asana_request(global_git, :post, 'sections/33333/addTask')
      .with(body: { data: { task: '44444' } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))

    stub_asana_request(global_git, :put, 'tasks/44444')
      .with(body: { data: { assignee: '88888' } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))
  end

  it 'assigns the current user to the current task and moves the task to the wip-section' do
    stub_asana_request(global_git, :get, 'tasks/44444')
      .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
      .to_return(body: Oj.dump({ data: { gid: '44444',
                                         name: 'Started task',
                                         assignee: nil,
                                         memberships: [{ section: { gid: '22222' } }],
                                         permalink_url: 'https://ta.sk/44444/URL' } },
                               mode: :json))

    local_git['path'] = '11111/44444'
    err_output = StringIO.new
    output = StringIO.new
    argv = %w[start asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq <<~TXT
      ===== START asana =====
      https://ta.sk/44444/URL
      Assigning task to user: Name of user
      Moving task to section: WIP
    TXT

    expect(output.string).to eq <<~TXT
      asana:11111/44444 # Started task
    TXT
  end

  context 'when the task is already in the WIP section' do
    it 'does not move the task' do
      stub_asana_request(global_git, :get, 'tasks/44444')
        .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: '44444',
                                           name: 'Started task',
                                           assignee: nil,
                                           memberships: [{ section: { gid: '33333', name: 'WIP' } }],
                                           permalink_url: 'https://ta.sk/44444/URL' } },
                                 mode: :json))

      local_git['path'] = '11111/44444'
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== START asana =====
        https://ta.sk/44444/URL
        Assigning task to user: Name of user
        Task already in section: WIP
      TXT

      expect(output.string).to eq <<~TXT
        asana:11111/44444 # Started task
      TXT
    end
  end

  context 'when the task is already assigned to the current user' do
    it 'does not reassign the task' do
      stub_asana_request(global_git, :get, 'tasks/44444')
        .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: '44444',
                                           name: 'Started task',
                                           assignee: { gid: '88888' },
                                           memberships: [{ section: { gid: '22222' } }],
                                           permalink_url: 'https://ta.sk/44444/URL' } },
                                 mode: :json))

      local_git['path'] = '11111/44444'
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== START asana =====
        https://ta.sk/44444/URL
        You are already assigned to this task
        Moving task to section: WIP
      TXT

      expect(output.string).to eq <<~TXT
        asana:11111/44444 # Started task
      TXT
    end
  end

  context 'when the task is assigned to another user' do
    it 'lets the user decide whether or not to reassign it' do
      stub_asana_request(global_git, :get, 'tasks/44444')
        .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: '44444',
                                           name: 'Started task',
                                           assignee: { gid: '12121', name: 'Another assigned user' },
                                           memberships: [{ section: { gid: '22222' } }],
                                           permalink_url: 'https://ta.sk/44444/URL' } },
                                 mode: :json))

      stub_asana_request(global_git, :post, 'sections/33333/addTask')
        .with(body: { data: { task: '44444' } })
        .to_return(body: Oj.dump({ data: {} }, mode: :json))

      stub_asana_request(global_git, :put, 'tasks/44444')
        .with(body: { data: { assignee: '88888' } })
        .to_return(body: Oj.dump({ data: {} }, mode: :json))

      stub_asana_request(global_git, :post, 'tasks')
        .with(body: { data: { name: 'A task', notes: 'Notes', projects: ['11111'] } })
        .to_return(body: Oj.dump({ data: { gid: '44444', name: 'A task' } }, mode: :json))

      local_git['path'] = '11111/44444'

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[start asana]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== START asana =====\n")
      expect(err_output.gets).to eq("https://ta.sk/44444/URL\n")
      expect(err_output.gets).to eq("Task is assigned to: Another assigned user, take over?\n")
      expect(err_output.gets).to eq('(y / n): ')

      input.puts('y')

      expect(err_output.gets).to eq("Reassigning task to user: Name of user\n")
      expect(err_output.gets).to eq("Moving task to section: WIP\n")
      expect(output.gets).to eq("asana:11111/44444 # Started task\n")

      thr.join
    end
  end

  context 'when using --set flag' do
    it 'overrides the current task' do
      stub_asana_request(global_git, :get, 'tasks/44444')
        .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: '44444',
                                           name: 'Started task',
                                           assignee: nil,
                                           memberships: [{ section: { gid: '22222' } }],
                                           permalink_url: 'https://ta.sk/44444/URL' } },
                                 mode: :json))

      local_git['path'] = '11111/10101'
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana:11111/44444 -s]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== START asana:11111/44444 -s =====
        https://ta.sk/44444/URL
        Assigning task to user: Name of user
        Moving task to section: WIP
        Current task updated
      TXT

      expect(output.string).to eq <<~TXT
        asana:11111/44444 # Started task
      TXT

      expect(local_git['path']).to eq('11111/44444')
    end
  end

  context 'task is outside of current project' do
    it 'does not move the task - since the WIP section is stored per git repo' do
      stub_asana_request(global_git, :get, 'tasks/44444')
        .with(query: { opt_fields: 'name,memberships.section.name,assignee.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: '44444',
                                           name: 'Started task',
                                           assignee: nil,
                                           memberships: [{ section: { gid: '22222' } }],
                                           permalink_url: 'https://ta.sk/44444/URL' } },
                                 mode: :json))

      local_git['path'] = '20202'
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[start asana:11111/44444]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== START asana:11111/44444 =====
        https://ta.sk/44444/URL
        Assigning task to user: Name of user
        Task was not moved, this is not implemented for tasks outside current project
      TXT

      expect(output.string).to eq <<~TXT
        asana:11111/44444 # Started task
      TXT
    end
  end

  context 'when no current/specified task' do
    it 'aborts with correct error message' do
      argv = %w[start asana]
      cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, 'No current/specified project. Did you initialize Asana and pick a task?')
      )
    end
  end
end
