# frozen_string_literal: true

RSpec.describe Abt::GitConfig do
  describe '.local_available?' do
    after do
      Abt::GitConfig.remove_instance_variable '@local_available'
    end

    it 'calls "git config --local -l"' do
      system_call = nil

      allow(Open3).to receive(:popen3) do |received_system_call|
        system_call = received_system_call
      end

      Abt::GitConfig.local_available?

      expect(system_call).to eq('git config --local -l')
    end

    context 'when command was successful' do
      it 'is true' do
        stub_const 'Abt::GitConfig::LOCAL_CONFIG_AVAILABLE_CHECK_COMMAND', 'true'
        expect(Abt::GitConfig.local_available?).to be(true)
      end
    end

    context 'when command is unsuccessful' do
      it 'is false' do
        stub_const 'Abt::GitConfig::LOCAL_CONFIG_AVAILABLE_CHECK_COMMAND', 'false'
        expect(Abt::GitConfig.local_available?).to be(false)
      end
    end
  end
end
