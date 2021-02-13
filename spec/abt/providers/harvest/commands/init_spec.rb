# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Init) do
  context 'when local config is not available' do
    it 'aborts with "Must be run inside a git repository"' do
      initializer = Abt::Providers::Harvest::Configuration.method :new
      allow(Abt::Providers::Harvest::Configuration).to receive(:new) do |cli:|
        initializer.call(cli: cli).tap do |config|
          allow(config).to receive(:local_available?).and_return(nil?)
        end
      end

      cli = Abt::Cli.new(argv: %w[init harvest], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'Must be run inside a git repository')
    end
  end

  context 'when local config is available' do
    it 'prompts for a project and stores it in the configuration' do
      global_git = GitConfigMock.new('accessToken' => 'access_token', 'accountId' => 'account_id')
      local_git = GitConfigMock.new

      allow(Abt::GitConfig).to receive(:new) do |scope: 'local', **|
        scope == 'global' ? global_git : local_git
      end

      request_headers = {
        'Authorization' => "Bearer #{global_git['accessToken']}",
        'Harvest-Account-Id' => global_git['accountId'], 'Content-Type' => 'application/json'
      }
      response_data = {
        "project_assignments": [
          {
            "project": { "id": 27_701_618, "name": 'Internal EM' },
            "client": { "name": 'Abtion' },
            "task_assignments": [
              { "task": { "id": 14_628_589, "name": 'Asana (track time through Asana)' } }
            ]
          }
        ],
        "total_pages": 1
      }

      stub_request(:get, 'https://api.harvestapp.com/v2/users/me/project_assignments?page=1')
        .with(headers: request_headers)
        .to_return(body: Oj.dump(response_data, mode: :json))

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[init harvest]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(cli.prompt).to receive(:read_user_input) { input.gets }

        cli.perform
      end

      expect(err_output.gets).to eq("===== INIT HARVEST =====\n")
      expect(err_output.gets).to eq("Fetching projects...\n")
      expect(err_output.gets).to eq("Select a project\n")
      expect(err_output.gets).to eq('Enter search: ')

      input.puts('Search that does not match anything')

      expect(err_output.gets).to eq("No matches\n")
      expect(err_output.gets).to eq('Enter search: ')

      input.puts('EM')

      expect(err_output.gets).to eq("Select a project:\n")
      expect(err_output.gets).to eq("(1) Abtion > Internal EM\n")
      expect(err_output.gets).to eq('(1, q: back): ')

      input.puts('1')

      expect(err_output.gets).to eq("Selected: (1) Abtion > Internal EM\n")
      expect(output.gets).to eq("harvest:27701618 # Abtion > Internal EM\n")

      thr.join

      expect(local_git['path']).to eq('27701618')
    end
  end
end
