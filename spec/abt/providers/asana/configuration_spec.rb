# frozen_string_literal: true

RSpec.describe(Abt::Providers::Asana::Configuration, :asana) do
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.asana").and_return(global_git)
  end

  describe "#access_token" do
    it "returns the access token stored in global git config" do
      global_git["accessToken"] = "token"

      config = Abt::Providers::Asana::Configuration.new(cli: nil)

      expect(config.access_token).to be(global_git["accessToken"])
    end

    context "when there's no access token yet" do
      it "prompts the user for an access token, then stores and returns it" do
        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Asana::Configuration.new(cli: cli)

          expect(config.access_token).to eq("filled in access token")
        end

        expect(err_output.gets).to include("Enter access token")

        input.puts("filled in access token")

        thr.join

        expect(global_git["accessToken"]).to eq("filled in access token")
      end
    end
  end

  describe "#workspace_gid" do
    it "returns the workspace gid stored in global git config" do
      global_git["workspaceGid"] = "gid"

      config = Abt::Providers::Asana::Configuration.new(cli: nil)

      expect(config.workspace_gid).to be(global_git["workspaceGid"])
    end

    context "when there's no workspace gid yet" do
      it "fetches the user's workspace from asana" do
        global_git["accessToken"] = "access_token"
        stub_asana_request(global_git, :get, "workspaces")
          .with(query: { limit: 100, opt_fields: "name" })
          .to_return(body: Oj.dump({ data: [{ gid: "11111", name: "Workspace" }] }, mode: :json))

        err_output = StringIO.new

        cli = Abt::Cli.new(argv: [], err_output: err_output, output: null_stream)

        config = Abt::Providers::Asana::Configuration.new(cli: cli)

        expect(config.workspace_gid).to eq("11111")
        expect(err_output.string).to eq(<<~TXT)
          Fetching workspaces...
          Selected Asana workspace: Workspace
        TXT
      end

      context "when user has access to multiple workspaces" do
        it "allows the user to select a workspace" do
          workspaces = [
            { gid: "11111", name: "Workspace A" },
            { gid: "22222", name: "Workspace B" }
          ]

          global_git["accessToken"] = "access_token"
          stub_asana_request(global_git, :get, "workspaces")
            .with(query: { limit: 100, opt_fields: "name" })
            .to_return(body: Oj.dump({ data: workspaces }, mode: :json))

          input = QueueIO.new
          err_output = QueueIO.new

          thr = Thread.new do
            cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
            allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

            config = Abt::Providers::Asana::Configuration.new(cli: cli)

            expect(config.workspace_gid).to eq("22222")
          end

          expect(err_output.gets).to eq("Fetching workspaces...\n")
          expect(err_output.gets).to eq("Select Asana workspace:\n")
          expect(err_output.gets).to eq("(1) Workspace A\n")
          expect(err_output.gets).to eq("(2) Workspace B\n")
          expect(err_output.gets).to eq("(1-2): ")

          input.puts("2")

          expect(err_output.gets).to eq("Selected: (2) Workspace B\n")

          thr.join
        end
      end

      context "when user does not have access to any workspaces" do
        it "fetches the user's workspace from asana" do
          global_git["accessToken"] = "access_token"
          stub_asana_request(global_git, :get, "workspaces")
            .with(query: { limit: 100, opt_fields: "name" })
            .to_return(body: Oj.dump({ data: [] }, mode: :json))

          err_output = StringIO.new

          cli = Abt::Cli.new(argv: [], err_output: err_output, output: null_stream)

          config = Abt::Providers::Asana::Configuration.new(cli: cli)

          expect { config.workspace_gid }.to(
            raise_error(Abt::Cli::Abort,
                        "Your asana access token does not have access to any workspaces")
          )
        end
      end
    end
  end

  describe "#wip_section_gid" do
    it "returns the WIP section gid stored in local git config" do
      local_git = GitConfigMock.new(data: { "wipSectionGid" => "gid" })
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

      config = Abt::Providers::Asana::Configuration.new(cli: nil)

      expect(config.wip_section_gid).to be(local_git["wipSectionGid"])
    end

    context "when there's no WIP section gid yet" do
      it "allows the user to select a WIP section" do
        local_git = GitConfigMock.new(data: { "path" => "11111" })
        allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

        sections = [
          { gid: "22222", name: "Backlog" },
          { gid: "33333", name: "WIP" }
        ]

        global_git["accessToken"] = "access_token"
        stub_asana_request(global_git, :get, "projects/11111/sections")
          .with(query: { limit: 100, opt_fields: "name" })
          .to_return(body: Oj.dump({ data: sections }, mode: :json))

        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Asana::Configuration.new(cli: cli)

          expect(config.wip_section_gid).to eq("33333")
        end

        expect(err_output.gets).to eq("Fetching sections...\n")
        expect(err_output.gets).to eq("Select WIP (Work In Progress) section:\n")
        expect(err_output.gets).to eq("(1) Backlog\n")
        expect(err_output.gets).to eq("(2) WIP\n")
        expect(err_output.gets).to eq("(1-2): ")

        input.puts("2")

        expect(err_output.gets).to eq("Selected: (2) WIP\n")

        thr.join
      end
    end
  end

  describe "#finalized_section_gid" do
    it "returns the finalized section gid stored in local git config" do
      local_git = GitConfigMock.new(data: { "finalizedSectionGid" => "gid" })
      allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

      config = Abt::Providers::Asana::Configuration.new(cli: nil)

      expect(config.finalized_section_gid).to be(local_git["finalizedSectionGid"])
    end

    context "when there's no finalized section gid yet" do
      it "allows the user to select a finalized section" do
        local_git = GitConfigMock.new(data: { "path" => "11111" })
        allow(Abt::GitConfig).to receive(:new).with("local", "abt.asana").and_return(local_git)

        sections = [
          { gid: "22222", name: "WIP" },
          { gid: "33333", name: "Finalized" }
        ]

        global_git["accessToken"] = "access_token"
        stub_asana_request(global_git, :get, "projects/11111/sections")
          .with(query: { limit: 100, opt_fields: "name" })
          .to_return(body: Oj.dump({ data: sections }, mode: :json))

        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Asana::Configuration.new(cli: cli)

          expect(config.finalized_section_gid).to eq("33333")
        end

        expect(err_output.gets).to eq("Fetching sections...\n")
        expect(err_output.gets).to eq("Select section for finalized tasks (E.g. \"Merged\"):\n")
        expect(err_output.gets).to eq("(1) WIP\n")
        expect(err_output.gets).to eq("(2) Finalized\n")
        expect(err_output.gets).to eq("(1-2): ")

        input.puts("2")

        expect(err_output.gets).to eq("Selected: (2) Finalized\n")

        thr.join
      end
    end
  end
end
