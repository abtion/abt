# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::BranchName, :devops) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:board_id) { "abc123" }
  let(:work_item_id) { 222_222 }
  let(:work_item) do
    { id: work_item_id,
      fields: { 'System.Title': " Work Item \#$\#$ name." } }
  end

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  def stub_work_items
    stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
      .with(query: { ids: work_item_id.to_s })
      .to_return(body: Oj.dump({ value: [work_item] },
                               mode: :json))
  end

  it "prints a git branch name suggestion for the work item" do
    stub_work_items

    local_git["path"] = "org-name/project-name/#{board_id}/#{work_item_id}"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[branch-name devops]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== BRANCH-NAME devops =====
    TXT

    expect(output.string).to eq(<<~TXT)
      #{work_item_id}-work-item-name
    TXT
  end

  context "when ARI doesn't include a board" do
    it "aborts with correct message" do
      local_git["path"] = "org-name/project-name"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error do |error|
        expect(error).to be_a(Abt::Cli::Abort)
        expect(error.message).to include("No current/specified board")
      end
    end
  end

  context "when ARI doesn't include a work item" do
    it "aborts with correct message" do
      local_git["path"] = "org-name/project-name/#{board_id}"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error do |error|
        expect(error).to be_a(Abt::Cli::Abort)
        expect(error.message).to include("No current/specified work item")
      end
    end
  end

  context "when the work item is invalid" do
    it "aborts with correct message" do
      stub_devops_request(global_git, "org-name", "project-name", :get, "wit/workitems")
        .with(query: { ids: "00000" })
        .to_return(status: 404)

      local_git["path"] = "org-name/project-name/#{board_id}/00000"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[branch-name devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, <<~TXT)
        Unable to find work item for configuration:
        devops:org-name/project-name/#{board_id}/00000
      TXT
    end
  end
end
