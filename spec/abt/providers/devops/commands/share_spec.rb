# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Share, :devops) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with('local', 'abt.devops').and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with('global', 'abt.devops').and_return(global_git)
  end

  it 'prints the current/specified ARI' do
    local_git['path'] = 'org-name/project-name/aaaaaaaa/23232'

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[share devops]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq <<~TXT
      ===== SHARE devops =====
    TXT

    expect(output.string).to eq <<~TXT
      devops:org-name/project-name/aaaaaaaa/23232
    TXT
  end

  context 'when no path current specified path' do
    it 'prints the current/specified ARI' do
      argv = %w[share devops]
      cli = Abt::Cli.new(argv: argv, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort, 'No current/specified board. Did you initialize DevOps?')
      )
    end
  end
end
