# frozen_string_literal: true

RSpec.describe Abt do
  describe '.provider_names' do
    it 'returns all constants under Providers as sorted command names' do
      allow(Abt::Providers).to receive(:constants).and_return(%i[
                                                                Asana
                                                                Harvest
                                                                Devops
                                                                AnotherProvider
                                                              ])

      expect(Abt.provider_names).to eq(%w[another-provider asana devops harvest])
    end
  end

  describe '.provider_module(name)' do
    it 'returns the provider module for the specified command name' do
      provider_module = Module.new {}

      allow(Abt::Providers).to receive(:const_defined?).with('ModuleName').and_return(true)
      allow(Abt::Providers).to receive(:const_get).with('ModuleName').and_return(provider_module)

      expect(Abt.provider_module('module-name')).to eq(provider_module)
    end
  end
end
