# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Tasks, :harvest) do
  let(:harvest_credentials) { { 'accessToken' => 'access_token', 'accountId' => 'account_id' } }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }
  let(:local_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.harvest').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.harvest').and_return(global_git)
  end

  context 'when project specified' do
    before do
      stub_get_project_assignments(global_git, [
                                     {
                                       "project": { "id": 27_701_618, "name": 'Project' },
                                       "client": { "name": 'Abtion' },
                                       "task_assignments": [
                                         { "task": { "id": 14_628_589, "name": 'Task 1' } },
                                         { "task": { "id": 14_628_590, "name": 'Task 2' } }
                                       ]
                                     }
                                   ])
    end

    it 'prints all tasks for the project' do
      err_output = StringIO.new
      output = StringIO.new
      argv = ['tasks', 'harvest:27701618']

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq <<~TXT
        ===== TASKS harvest:27701618 =====
        Fetching tasks...
      TXT

      expect(output.string).to eq <<~TXT
        harvest:27701618/14628589 # Project > Task 1
        harvest:27701618/14628590 # Project > Task 2
      TXT
    end
  end

  context 'when no project specified' do
    it 'aborts with correct message' do
      cli = Abt::Cli.new(argv: %w[tasks harvest], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'No current/specified project. Did you initialize Harvest?')
    end
  end
end
