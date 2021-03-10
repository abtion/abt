# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Configuration, :harvest) do
  let(:global_git) { GitConfigMock.new }

  before do
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)
  end

  describe "#access_token" do
    it "returns the access token stored in global git config" do
      global_git["accessToken"] = "token"

      config = Abt::Providers::Harvest::Configuration.new(cli: nil)

      expect(config.access_token).to be(global_git["accessToken"])
    end

    context "when there's no access token yet" do
      it "prompts the user for an access token, then stores and returns it" do
        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Harvest::Configuration.new(cli: cli)

          expect(config.access_token).to eq("filled in access token")
        end

        expect(err_output.gets).to include("Enter access token")

        input.puts("filled in access token")

        thr.join

        expect(global_git["accessToken"]).to eq("filled in access token")
      end
    end
  end

  describe "#account_id" do
    it "returns the account id stored in global git config" do
      global_git["accountId"] = "id"

      config = Abt::Providers::Harvest::Configuration.new(cli: nil)

      expect(config.account_id).to be(global_git["accountId"])
    end

    context "when there's no account id yet" do
      it "prompts the user for an account id, then stores and returns it" do
        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: [], input: input, err_output: err_output, output: null_stream)
          allow(cli.prompt).to receive(:read_user_input) { input.gets.strip }

          config = Abt::Providers::Harvest::Configuration.new(cli: cli)

          expect(config.account_id).to eq("filled in account id")
        end

        expect(err_output.gets).to include("Enter account id")

        input.puts("filled in account id")

        thr.join

        expect(global_git["accountId"]).to eq("filled in account id")
      end
    end
  end

  describe "#user_id" do
    it "returns the user id stored in global git config" do
      global_git["userId"] = "id"

      config = Abt::Providers::Harvest::Configuration.new(cli: nil)

      expect(config.user_id).to be(global_git["userId"])
    end

    context "when there's no user_id yet" do
      it "prompts the user for an user_id, then stores and returns it" do
        global_git["accessToken"] = "accessToken"
        global_git["accountId"] = "accountId"

        stub_request(:get, "https://api.harvestapp.com/v2/users/me")
          .with(headers: request_headers_for_git_config(global_git))
          .to_return(body: Oj.dump({ id: "userId" }, mode: :json))

        config = Abt::Providers::Harvest::Configuration.new(cli: nil)

        expect(config.user_id).to eq("userId")
      end
    end
  end
end
