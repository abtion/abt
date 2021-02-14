# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Pick, :harvest) do
  context 'when local config is available' do
    let(:harvest_credentials) { { 'accessToken' => 'access_token', 'accountId' => 'account_id' } }
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with('local', 'abt.harvest').and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with('global', 'abt.harvest').and_return(global_git)

      stub_project_assignments_request(global_git, [
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

    it 'prompts for a project and stores it in the configuration' do
      local_git['path'] = '27701618'

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[pick harvest]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(cli.prompt).to receive(:read_user_input) { input.gets }

        cli.perform
      end

      expect(err_output.gets).to eq("===== PICK harvest =====\n")
      expect(err_output.gets).to eq("Project\n")
      expect(err_output.gets).to eq("Select a task:\n")
      expect(err_output.gets).to eq("(1) Task 1\n")
      expect(err_output.gets).to eq("(2) Task 2\n")
      expect(err_output.gets).to eq('(1-2): ')

      input.puts('4')

      expect(err_output.gets).to eq("Invalid selection\n")
      expect(err_output.gets).to eq('(1-2): ')

      input.puts('1')

      expect(err_output.gets).to eq("Selected: (1) Task 1\n")
      expect(output.gets).to eq("harvest:27701618/14628589 # Project > Task 1\n")

      thr.join

      expect(local_git['path']).to eq('27701618/14628589')
    end

    context 'when dry-run' do
      it 'doesn\'t update the configuration' do
        local_git['path'] = '27701618'

        output = StringIO.new
        argv = %w[pick harvest -d]

        cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: output)
        allow(cli.prompt).to receive(:read_user_input) { '1' } # Rig the cli to select option 1

        cli.perform

        expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
        expect(local_git['path']).to eq('27701618')
      end
    end

    context 'when no project has been selected yet' do
      it 'aborts with "No current/specified project. Did you initialize Harvest?"' do
        cli = Abt::Cli.new(argv: %w[pick harvest], output: null_stream)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'No current/specified project. Did you initialize Harvest?')
      end
    end
  end

  context 'when local config is not available' do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with('local', 'abt.harvest').and_return(local_git)

      cli = Abt::Cli.new(argv: %w[pick harvest], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'Must be run inside a git repository')
    end
  end
end
