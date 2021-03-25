# frozen_string_literal: true

RSpec.describe(Abt::Providers::Devops::Services::ProjectPicker) do
  describe "#project_url" do
    it "asks until it gets a valid url" do
      err_output = StringIO.new

      cli = Abt::Cli.new(input: null_tty, err_output: err_output, output: null_stream)
      board_picker = Abt::Providers::Devops::Services::ProjectPicker.new(cli: cli)

      allow(Abt::Helpers).to receive(:read_user_input).and_return("invalid_url",
                                                                  "https://dev.azure.com/org-name/project-name")

      expect(board_picker.send(:project_url)).to eq("https://dev.azure.com/org-name/project-name")
      expect(err_output.string).to include("Invalid URL")
    end
  end

  describe "#project_url_match" do
    it "matches dev.azure.com-style urls" do
      board_picker = Abt::Providers::Devops::Services::ProjectPicker.new(cli: nil)

      url = "https://dev.azure.com/org-name/project-name"
      allow(board_picker).to receive(:prompt_url).and_return(url)

      match = board_picker.send(:project_url_match)

      expect(match["organization"]).to eq("org-name")
      expect(match["project"]).to eq("project-name")
    end

    it "matches visualstudio.com-style urls" do
      board_picker = Abt::Providers::Devops::Services::ProjectPicker.new(cli: nil)

      url = "https://org-name.visualstudio.com/project-name"
      allow(board_picker).to receive(:prompt_url).and_return(url)

      match = board_picker.send(:project_url_match)

      expect(match["organization"]).to eq("org-name")
      expect(match["project"]).to eq("project-name")
    end
  end
end
