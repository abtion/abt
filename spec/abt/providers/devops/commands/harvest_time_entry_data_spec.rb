# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Commands::HarvestTimeEntryData, :devops) do
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: devops_credentials) }
  let(:board_name) { "board" }
  let(:work_item_id) { 222_222 }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.devops").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  def stub_work_items
    stub_devops_request(global_git, "org-name", :get, "_apis/wit/workitems")
      .with(query: { ids: work_item_id.to_s })
      .to_return(body: Oj.dump({ value: [{ id: work_item_id,
                                           fields: { 'System.Title': "Work Item \#$\#$ name",
                                                     "System.TeamProject": "project-name" } }] },
                               mode: :json))
  end

  it "prints data that can be merged into a harvest time entry to link it to the work item" do
    stub_work_items

    local_git["path"] = "org-name/project-name/team-name/#{board_name}/#{work_item_id}"

    err_output = StringIO.new
    output = StringIO.new
    argv = %w[harvest-time-entry-data devops]

    allow(output).to receive(:isatty).and_return(true)

    cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
    cli.perform

    expect(err_output.string).to eq(<<~TXT)
      ===== HARVEST-TIME-ENTRY-DATA devops =====
    TXT

    expect(Oj.load(output.string, symbol_keys: true)).to eq(
      notes: "Azure DevOps  ##{work_item_id} - Work Item \#$\#$ name",
      external_reference: {
        id: work_item_id.to_s,
        group_id: "AzureDevOpsWorkItem",
        permalink: "https://org-name.visualstudio.com/project-name/_workitems/edit/#{work_item_id}"
      }
    )
  end

  context "when ARI doesn't include a board" do
    it "aborts with correct message" do
      local_git["path"] = "org-name/project-name/team-name"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[harvest-time-entry-data devops]

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
      local_git["path"] = "org-name/project-name/team-name/#{board_name}"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[harvest-time-entry-data devops]

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
      stub_devops_request(global_git, "org-name", :get, "_apis/wit/workitems")
        .with(query: { ids: "00000" })
        .to_return(status: 404)

      local_git["path"] = "org-name/project-name/team-name/#{board_name}/00000"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[harvest-time-entry-data devops]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, <<~TXT)
        Unable to find work item for configuration:
        devops:org-name/project-name/team-name/#{board_name}/00000
      TXT
    end
  end
end
