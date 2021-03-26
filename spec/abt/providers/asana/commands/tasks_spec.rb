# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Commands::Tasks, :asana) do
  let(:global_git) { GitConfigMock.new(data: asana_credentials) }
  let(:local_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)
  end

  context "when project specified" do
    before do
      stub_asana_request(global_git, :get, "projects/11111")
        .with(query: { opt_fields: "name,permalink_url" })
        .to_return(body: Oj.dump({ data: { gid: "11111", name: "Project" } }, mode: :json))

      stub_asana_request(global_git, :get, "tasks")
        .with(query: { limit: 100, project: "11111", opt_fields: "name,completed" })
        .to_return(body: Oj.dump({ data: [
          { gid: "22222", name: "Task A", completed: false },
          { gid: "33333", name: "Task B", completed: false },
          { gid: "44444", name: "Task C", completed: true }
        ] }, mode: :json))
    end

    it "prints all tasks for the project" do
      err_output = StringIO.new
      output = StringIO.new
      argv = ["tasks", "asana:11111"]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== TASKS asana:11111 =====
        Fetching project...
        Fetching tasks...
      TXT

      expect(output.string).to eq(<<~TXT)
        asana:11111/22222 # Task A
        asana:11111/33333 # Task B
      TXT
    end
  end
end
