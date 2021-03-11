# frozen_string_literal: true

RSpec.describe Abt::Cli::Prompt do
  describe "#text" do
    it "prints the specified question and returns the user input" do
      output = StringIO.new
      prompt = Abt::Cli::Prompt.new(output: output)
      allow(Abt::Helpers).to receive(:read_user_input).and_return("input")

      expect(prompt.text("Input some text here")).to eq("input")
      expect(output.string).to eq("Input some text here: ")
    end
  end

  describe "#boolean" do
    it "prints the question followed by (y / n) prompt" do
      output = StringIO.new
      prompt = Abt::Cli::Prompt.new(output: output)
      allow(Abt::Helpers).to receive(:read_user_input).and_return("y")

      prompt.boolean("Do this?")

      expect(output.string).to eq("Do this?\n(y / n): ")
    end

    context 'when user inputs "y"' do
      it "returns true" do
        prompt = Abt::Cli::Prompt.new(output: StringIO.new)
        allow(Abt::Helpers).to receive(:read_user_input).and_return("y")

        expect(prompt.boolean("Do this?")).to be(true)
      end
    end

    context 'when user inputs "n"' do
      it "returns false" do
        prompt = Abt::Cli::Prompt.new(output: StringIO.new)
        allow(Abt::Helpers).to receive(:read_user_input).and_return("n")

        expect(prompt.boolean("Do this?")).to be(false)
      end
    end

    context "when user inputs something else" do
      it "keeps prompting until it receives y or n" do
        output = StringIO.new
        prompt = Abt::Cli::Prompt.new(output: output)
        allow(Abt::Helpers).to receive(:read_user_input).and_return("x", "wrong", "y")

        expect(prompt.boolean("Do this?")).to be(true)
        expect(output.string).to eq([
          "Do this?",
          "(y / n): Invalid choice",
          "(y / n): Invalid choice",
          "(y / n): "
        ].join("\n"))

        expect(Abt::Helpers).to have_received(:read_user_input).thrice
      end
    end
  end

  describe "#choice" do
    it "prints the specified question, available options and a prompt" do
      output = StringIO.new
      prompt = Abt::Cli::Prompt.new(output: output)
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1")

      option1 = { "name" => "First" }
      option2 = { "name" => "Second" }

      prompt.choice("Pick an option", [option1, option2])

      expect(output.string).to eq([
        "Pick an option:",
        "(1) First",
        "(2) Second",
        "(1-2): Selected: (1) First",
        ""
      ].join("\n"))
    end

    it "returns the picked option" do
      prompt = Abt::Cli::Prompt.new(output: StringIO.new)
      allow(Abt::Helpers).to receive(:read_user_input).and_return("1")

      option1 = { "name" => "First" }
      option2 = { "name" => "Second" }

      expect(prompt.choice("Pick an option", [option1, option2])).to be(option1)
    end

    context "when invalid option is selected" do
      it "keeps prompting until it receives a valid option" do
        prompt = Abt::Cli::Prompt.new(output: StringIO.new)
        allow(Abt::Helpers).to receive(:read_user_input).and_return("w", "x", "d", "0", "3", "2")

        option1 = { "name" => "First" }
        option2 = { "name" => "Second" }

        expect(prompt.choice("Pick an option", [option1, option2])).to be(option2)
      end
    end

    context "when an empty list of options is provided" do
      it "returns nil" do
        prompt = Abt::Cli::Prompt.new(output: StringIO.new)
        expect do
          prompt.choice("Pick an option", [])
        end.to raise_error(Abt::Cli::Abort, "No available options")
      end
    end

    context "when nil_option is present" do
      it "prints nil option" do
        output = StringIO.new
        prompt = Abt::Cli::Prompt.new(output: output)
        allow(Abt::Helpers).to receive(:read_user_input).and_return("1")

        prompt.choice("Pick an option", [{ "name" => "Option" }], nil_option: ["x", "e(x)it"])

        expect(output.string).to include("(1, x: e(x)it):")
      end

      context "when an empty list of options is provided" do
        it "returns nil" do
          output = StringIO.new
          prompt = Abt::Cli::Prompt.new(output: output)

          expect(prompt.choice("Pick an option", [], nil_option: "quit")).to be(nil)
          expect(output.string).to include("No available options")
        end
      end

      context "when nil ioption is picked" do
        it "returns nil" do
          prompt = Abt::Cli::Prompt.new(output: StringIO.new)
          allow(Abt::Helpers).to receive(:read_user_input).and_return("q")

          expect(prompt.choice("Pick an option", [{ "name" => "Option" }], nil_option: true)).to eq(nil)
        end
      end
    end
  end
end
