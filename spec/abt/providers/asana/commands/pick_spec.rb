# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Pick, :asana) do
  context 'when local config is available' do
    let(:asana_credentials) { { 'accessToken' => 'access_token' } }
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: asana_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with('local', 'abt.asana').and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with('global', 'abt.asana').and_return(global_git)

      stub_asana_request(global_git, :get, 'projects/11111')
        .with(query: { opt_fields: 'name' })
        .to_return(body: Oj.dump({ data: { gid: '11111', name: 'Project', permalink_url: 'https://proj.ect/11111/URL' } }, mode: :json))

      stub_asana_request(global_git, :get, 'projects/11111/sections')
        .with(query: { limit: 100, opt_fields: 'name' })
        .to_return(body: Oj.dump({ data: [
                                   { gid: '22222', name: 'Section A' },
                                   { gid: '33333', name: 'Section B' }
                                 ] }, mode: :json))

      stub_asana_request(global_git, :get, 'tasks')
        .with(query: { limit: 100, section: '22222', opt_fields: 'name,completed,permalink_url' })
        .to_return(body: Oj.dump({ data: [
                                   { gid: '44444', name: 'Task A', permalink_url: 'https://ta.sk/44444/URL' },
                                   { gid: '55555', name: 'Task B', permalink_url: 'https://ta.sk/55555/URL' }
                                 ] }, mode: :json))

      # Empty section
      stub_asana_request(global_git, :get, 'tasks')
        .with(query: { limit: 100, section: '33333', opt_fields: 'name,completed,permalink_url' })
        .to_return(body: Oj.dump({ data: [] }, mode: :json))
    end

    it 'prompts for a task and stores it in the configuration' do
      local_git['path'] = '11111'

      input = QueueIO.new
      err_output = QueueIO.new
      output = QueueIO.new
      argv = %w[pick asana]

      thr = Thread.new do
        cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
        allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== PICK asana =====\n")
      expect(err_output.gets).to eq("Project\n")
      expect(err_output.gets).to eq("Fetching sections...\n")
      expect(err_output.gets).to eq("Which section?:\n")
      expect(err_output.gets).to eq("(1) Section A\n")
      expect(err_output.gets).to eq("(2) Section B\n")
      expect(err_output.gets).to eq('(1-2): ')

      input.puts('2')

      expect(err_output.gets).to eq("Selected: (2) Section B\n")
      expect(err_output.gets).to eq("Fetching tasks...\n")
      expect(err_output.gets).to eq("Section is empty\n")

      expect(err_output.gets).to eq("Which section?:\n")
      expect(err_output.gets).to eq("(1) Section A\n")
      expect(err_output.gets).to eq("(2) Section B\n")
      expect(err_output.gets).to eq('(1-2): ')

      input.puts('1')

      expect(err_output.gets).to eq("Selected: (1) Section A\n")
      expect(err_output.gets).to eq("Fetching tasks...\n")
      expect(err_output.gets).to eq("Select a task:\n")
      expect(err_output.gets).to eq("(1) Task A\n")
      expect(err_output.gets).to eq("(2) Task B\n")
      expect(err_output.gets).to eq('(1-2, q: back): ')

      input.puts('q')

      expect(err_output.gets).to eq("Which section?:\n")
      expect(err_output.gets).to eq("(1) Section A\n")
      expect(err_output.gets).to eq("(2) Section B\n")
      expect(err_output.gets).to eq('(1-2): ')

      input.puts('1')

      expect(err_output.gets).to eq("Selected: (1) Section A\n")
      expect(err_output.gets).to eq("Fetching tasks...\n")
      expect(err_output.gets).to eq("Select a task:\n")
      expect(err_output.gets).to eq("(1) Task A\n")
      expect(err_output.gets).to eq("(2) Task B\n")
      expect(err_output.gets).to eq('(1-2, q: back): ')

      input.puts('1')

      expect(err_output.gets).to eq("Selected: (1) Task A\n")
      expect(output.gets).to eq("asana:11111/44444 # Task A\n")
      expect(err_output.gets).to eq("https://ta.sk/44444/URL\n")

      thr.join

      expect(local_git['path']).to eq('11111/44444')
    end

    context 'when dry-run' do
      it 'doesn\'t update the configuration' do
        local_git['path'] = '11111'

        output = StringIO.new
        argv = %w[pick asana -d]

        cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: output)

        # Rig the cli to select option 1 for both section and task
        allow(cli.prompt).to receive(:read_user_input).and_return('1', '1')

        cli.perform

        expect(output.string).to eq("asana:11111/44444 # Task A\n")
        expect(local_git['path']).to eq('11111')
      end
    end

    context 'when no project has been selected yet' do
      it 'aborts with "No current/specified project. Did you initialize Asana?"' do
        cli = Abt::Cli.new(argv: %w[pick asana], output: null_stream)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'No current/specified project. Did you initialize Asana?')
      end
    end
  end

  context 'when local config is not available' do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with('local', 'abt.asana').and_return(local_git)

      cli = Abt::Cli.new(argv: %w[pick asana], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, 'Must be run inside a git repository')
    end
  end
end
