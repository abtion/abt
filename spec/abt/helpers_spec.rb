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
end
