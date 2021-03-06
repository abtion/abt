# frozen_string_literal: true

RSpec.describe Abt::Helpers do
  describe ".const_to_command" do
    it "formats a ConstantName string into a command-name" do
      expect(Abt::Helpers.const_to_command("WorkItems")).to eq("work-items")
    end
  end

  describe ".command_to_const" do
    it "formats a command-name string into a ConstantName" do
      expect(Abt::Helpers.command_to_const("work-items")).to eq("WorkItems")
    end
  end

  describe ".read_user_input", :read_user_input do
    it "gets user input through /dev/tty" do
      input = instance_double(IO)

      allow(Abt::Helpers).to receive(:open).and_yield(input)
      allow(input).to receive(:gets).and_return("input\n")

      expect(Abt::Helpers.read_user_input).to eq("input")
      expect(Abt::Helpers).to have_received(:open).with("/dev/tty")
      expect(input).to have_received(:gets)
    end
  end
end
