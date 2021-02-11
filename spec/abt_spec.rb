# frozen_string_literal: true

RSpec.describe Abt do
  describe '.schemes' do
    it 'returns all constants under Providers as sorted command names' do
      allow(Abt::Providers).to receive(:constants).and_return(%i[
                                                                Asana
                                                                Harvest
                                                                Devops
                                                                AnotherProvider
                                                              ])

      expect(Abt.schemes).to eq(%w[another-provider asana devops harvest])
    end
  end

  describe '.scheme_provider(name)' do
    it 'returns the provider module for the specified command name' do
      scheme_provider = Module.new {}

      allow(Abt::Providers).to receive(:const_defined?).with('ModuleName').and_return(true)
      allow(Abt::Providers).to receive(:const_get).with('ModuleName').and_return(scheme_provider)

      expect(Abt.scheme_provider('module-name')).to eq(scheme_provider)
    end
  end
end
