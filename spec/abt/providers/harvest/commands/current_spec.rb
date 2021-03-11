# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Current, :harvest) do
  context "when local config is available" do
    let(:local_git) { GitConfigMock.new }
    let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

    before do
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
      allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)

      stub_get_project_assignments(global_git, [
        {
          project: { id: 27_701_618, name: "Project" },
          client: { name: "Abtion" },
          task_assignments: [
            { task: { id: 14_628_589, name: "Task 1" } },
            { task: { id: 14_628_590, name: "Task 2" } }
          ]
        }
      ])
    end

    it "prints the current ARI with project and task titles" do
      local_git["path"] = "27701618/14628589"

      err_output = StringIO.new
      output = StringIO.new
      argv = %w[current harvest]

      allow(output).to receive(:isatty).and_return(true)

      cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
      cli.perform

      expect(err_output.string).to eq(<<~TXT)
        ===== CURRENT harvest =====
      TXT

      expect(output.string).to eq(<<~TXT)
        harvest:27701618/14628589 # Project > Task 1
      TXT
    end

    context "when ARI doesn't include a task" do
      it "prints the current ARI with client and project titles." do
        local_git["path"] = "27701618"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current harvest]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to eq(<<~TXT)
          ===== CURRENT harvest =====
        TXT

        expect(output.string).to eq(<<~TXT)
          harvest:27701618 # Abtion > Project
        TXT
      end
    end

    context "when provided a path" do
      it "overrides the configuration" do
        local_git["path"] = "11111/22222"

        err_output = StringIO.new
        output = StringIO.new
        argv = ["current", "harvest:27701618/14628589"]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)
        cli.perform

        expect(err_output.string).to include("Configuration updated")
        expect(local_git["path"]).to eq("27701618/14628589")
      end
    end

    context "when the project is invalid" do
      it 'aborts with "Invalid project"' do
        local_git["path"] = "00000/14628589"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current harvest]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid project: 00000")
      end
    end

    context "when the task is invalid" do
      it 'aborts with "Invalid project"' do
        local_git["path"] = "27701618/00000"

        err_output = StringIO.new
        output = StringIO.new
        argv = %w[current harvest]

        allow(output).to receive(:isatty).and_return(true)

        cli = Abt::Cli.new(argv: argv, err_output: err_output, output: output)

        expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid task: 00000")
      end
    end
  end

  context "when local config is not available" do
    it 'aborts with "Must be run inside a git repository"' do
      local_git = GitConfigMock.new(available: false)

      allow(Abt::GitConfig).to receive(:new).and_call_original
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)

      cli = Abt::Cli.new(argv: %w[current harvest], output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Must be run inside a git repository")
    end
  end
end
