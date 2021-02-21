# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::BranchName, :devops) do
  let(:devops_credentials) do
    { 'organizations.org-name.username' => 'username',
      'organizations.org-name.accessToken' => 'accessToken' }
  end
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.devops').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.devops').and_return(global_git)

    stub_devops_request(global_git, 'org-name', 'project-name', :get, 'wit/workitems')
      .with(query: { ids: '22222' })
      .to_return(body: Oj.dump({ value: [{ id: 11_111,
                                           fields: { 'System.Title': 'Work Item #$#$ name' } }] },
                               mode: :json))
  end

  it 'prints a git branch name suggestion for the work item' do
    local_git['path'] = 'org-name/project-name/11111/22222'

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[branch-name devops]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq <<~TXT
      ===== BRANCH-NAME devops =====
    TXT

    expect(output.string).to eq <<~TXT
      11111-work-item-name
    TXT
  end

  context 'when ARI doesn\'t include a work item' do
    it 'aborts with correct message' do
      local_git['path'] = 'org-name/project-name/11111'

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, 'No current/specified work item. Did you pick a DevOps work item?')
      )
    end
  end

  context 'when the work item is invalid' do
    it 'aborts with correct message' do
      stub_devops_request(global_git, 'org-name', 'project-name', :get, 'wit/workitems')
        .with(query: { ids: '00000' })
        .to_return(status: 404)

      local_git['path'] = 'org-name/project-name/11111/00000'

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error Abt::Cli::Abort, [
        'Unable to find work item for configuration:',
        'devops:org-name/project-name/11111/00000'
      ].join("\n")
    end
  end
end