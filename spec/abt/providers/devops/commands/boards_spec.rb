# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::Boards, :devops) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  it "prints all boards" do
    stub_devops_request(global_git, "org-name", "project-name", :get, "work/boards")
      .to_return(body: Oj.dump({ value: [{ id: "abc111", name: "Board 1" },
                                         { id: "abc222", name: "Board 2" }] }, mode: :json))

    local_git["path"] = "org-name/project-name"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[boards devops]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== BOARDS devops =====
      https://org-name.visualstudio.com/project-name/_boards/board/Board%201
      https://org-name.visualstudio.com/project-name/_boards/board/Board%202
    TXT

    expect(output.string).to eq(<<~TXT)
      devops:org-name/project-name/abc111 # Board 1
      devops:org-name/project-name/abc222 # Board 2
    TXT
  end
end
