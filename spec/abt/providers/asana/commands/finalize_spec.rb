# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Finalize, :asana) do
  let(:asana_credentials) do
    {
      'accessToken' => 'access_token',
      'workspaceGid' => 'workspace_gid'
    }
  end
  let(:local_git) { GitConfigMock.new(data: { 'finalizedSectionGid' => finalized_section_id }) }
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }

  let(:user_id) { '1001' }
  let(:project_id) { '1002' }
  let(:finalized_section_id) { '1003' }
  let(:task_id) { '1004' }

  let(:stub_task_request) do
    stub_asana_request(global_git, :get, "tasks/#{task_id}")
      .with(query: { opt_fields: 'name,memberships.section.name,permalink_url' })
      .to_return(body: Oj.dump({ data: { gid: task_id,
                                         name: 'Task to finalize',
                                         memberships: [],
                                         permalink_url: "https://ta.sk/#{task_id}/URL" } },
                               mode: :json))
  end
  let(:stub_finalized_section_request) do
    stub_asana_request(global_git, :get, "sections/#{finalized_section_id}")
      .with(query: { opt_fields: 'name' })
      .to_return(body: Oj.dump({ data: { gid: finalized_section_id, name: 'Finalized' } }, mode: :json))
  end
  let(:stub_add_to_finalized_section_request) do
    stub_asana_request(global_git, :post, "sections/#{finalized_section_id}/addTask")
      .with(body: { data: { task: task_id } })
      .to_return(body: Oj.dump({ data: {} }, mode: :json))
  end

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.asana').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.asana').and_return(global_git)
  end

  it 'moves the task to the Finalized-section' do
    stub_task_request
    stub_finalized_section_request
    stub_add_to_finalized_section_request

    local_git['path'] = "#{project_id}/#{task_id}"
    err_output = StringIO.new
    output = StringIO.new
    argv = %w[finalize asana]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq <<~TXT
      ===== FINALIZE asana =====
      https://ta.sk/#{task_id}/URL
      Moving task to section: Finalized
    TXT

    expect(output.string).to eq <<~TXT
      asana:#{project_id}/#{task_id} # Task to finalize
    TXT
  end

  context 'when the task is already in the finalized section' do
    it 'does not move the task' do
      stub_finalized_section_request

      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: 'name,memberships.section.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: 'Task to finalize',
                                           memberships: [{ section: { gid: finalized_section_id,
                                                                      name: 'Finalized' } }],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      local_git['path'] = "#{project_id}/#{task_id}"
      err_output = StringIO.new
      output = StringIO.new
      argv = %w[finalize asana]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== FINALIZE asana =====
        https://ta.sk/#{task_id}/URL
        Task already in section: Finalized
      TXT

      expect(output.string).to eq <<~TXT
        asana:#{project_id}/#{task_id} # Task to finalize
      TXT
    end
  end

  context 'task is outside of current project' do
    it 'aborts with correct error message' do
      stub_asana_request(global_git, :get, "tasks/#{task_id}")
        .with(query: { opt_fields: 'name,memberships.section.name,permalink_url' })
        .to_return(body: Oj.dump({ data: { gid: task_id,
                                           name: 'Task outside of current project',
                                           memberships: [],
                                           permalink_url: "https://ta.sk/#{task_id}/URL" } },
                                 mode: :json))

      other_project_id = '32432432432'
      local_git['path'] = other_project_id
      argv = ['finalize', "asana:#{project_id}/#{task_id}"]

      cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, 'This is a no-op for tasks outside the current project')
      )
    end
  end

  context 'when no current/specified task' do
    it 'aborts with correct error message' do
      argv = %w[finalize asana]
      cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort,
                    'No current/specified project. Did you initialize Asana and pick a task?')
      )
    end
  end
end
