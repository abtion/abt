# frozen_string_literal: true

RSpec.describe Abt do
  describe ".schemes" do
    it "returns all constants under Providers as sorted command names" do
      allow(Abt::Providers).to receive(:constants).and_return([:Asana, :Harvest, :Devops,
                                                               :AnotherProvider])

      expect(Abt.schemes).to eq(%w[another-provider asana devops harvest])
    end
  end

  describe ".scheme_provider(name)" do
    it "returns the provider module for the specified command name" do
      scheme_provider = Module.new

      allow(Abt::Providers).to receive(:const_defined?).with("ModuleName").and_return(true)
      allow(Abt::Providers).to receive(:const_get).with("ModuleName").and_return(scheme_provider)

      expect(Abt.scheme_provider("module-name")).to eq(scheme_provider)
    end
  end

  describe ".configuration", :directory_config do
    it "returns an instance of Abt::DirectoryConfig" do
      expect(Abt.directory_config).to be_an(Abt::DirectoryConfig)
    end
  end
end
