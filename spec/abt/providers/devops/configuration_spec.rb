# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Configuration, :devops) do
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.devops").and_return(global_git)
  end

  describe "#username_for_organization" do
    it "returns the username stored in global git config" do
      global_git["organizations.org-name.username"] = "user@na.me"

      config = Abt::Providers::Devops::Configuration.new(cli: nil)

      expect(config.username_for_organization("org-name")).to be("user@na.me")
    end

    context "when there's no username yet" do
      it "prompts the user for an username, then stores and returns it" do
        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Devops::Configuration.new(cli: cli)

          expect(config.username_for_organization("org-name")).to eq("filled@in.username")
        end

        expect(err_output.gets).to include("Enter username")

        input.puts("filled@in.username")

        thr.join

        expect(global_git["organizations.org-name.username"]).to eq("filled@in.username")
      end
    end
  end

  describe "#access_token_for_organization" do
    it "returns the access token stored in global git config" do
      global_git["organizations.org-name.accessToken"] = "0123456789abcdefg"

      config = Abt::Providers::Devops::Configuration.new(cli: nil)

      expect(config.access_token_for_organization("org-name")).to be("0123456789abcdefg")
    end

    context "when there's no access token yet" do
      it "prompts the user for an access token, then stores and returns it" do
        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Devops::Configuration.new(cli: cli)

          expect(config.access_token_for_organization("org-name")).to eq("0123456789abcdefg")
        end

        expect(err_output.gets).to include("Enter access token")

        input.puts("0123456789abcdefg")

        thr.join

        expect(global_git["organizations.org-name.accessToken"]).to eq("0123456789abcdefg")
      end
    end
  end
end
