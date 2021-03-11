# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Projects, :harvest) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)

    stub_get_project_assignments(global_git, [
      {
        project: { id: 27_701_618, name: "Project" },
        client: { name: "Abtion" }
      },
      {
        project: { id: 27_701_619, name: "Project 2" },
        client: { name: "Abticon" }
      },
      {
        project: { id: 27_701_620, name: "Project 3" },
        client: { name: "Abiton" }
      }
    ])
  end

  it "prints all projects" do
    err_output = StringIO.new
    output = StringIO.new
    argv = %w[projects harvest]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== PROJECTS harvest =====
      Fetching projects...
    TXT

    expect(output.string).to eq(<<~TXT)
      harvest:27701618 # Abtion > Project
      harvest:27701619 # Abticon > Project 2
      harvest:27701620 # Abiton > Project 3
    TXT
  end
end
