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

    context 'when command is successful' do
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

  describe '#initialize' do
    it 'sets namespace and scope' do
      config = Abt::GitConfig.new(namespace: 'namespace', scope: 'local')

      expect(config.namespace).to be('namespace')
      expect(config.scope).to be('local')
    end

    it 'only allows namespaces "local" and "global"' do
      expect { Abt::GitConfig.new(scope: 'local') }.to_not raise_error
      expect { Abt::GitConfig.new(scope: 'global') }.to_not raise_error
      expect { Abt::GitConfig.new(scope: 'testing') }.to raise_error(ArgumentError)
    end
  end

  describe 'instance' do
    before do
      allow(Abt::GitConfig).to receive(:local_available?).and_return true
    end

    describe '#[]' do
      it 'uses the specified scope and prefixes the key with the namespace' do
        config = Abt::GitConfig.new(namespace: 'namespace', scope: 'global')

        allow(config).to receive(:`).and_return('')

        config['key']

        expect(config).to have_received(:`).with('git config --global --get "namespace.key"')
      end

      context 'when git config outputs a value' do
        it 'strips and returns the value' do
          config = Abt::GitConfig.new

          allow(config).to receive(:`).and_return("a value\n")

          expect(config['key']).to eq('a value')
        end
      end

      context 'when git config outputs nothing' do
        it 'returns nil' do
          config = Abt::GitConfig.new

          allow(config).to receive(:`).and_return('')

          expect(config['key']).to be_nil
        end
      end

      context 'when local scope is not available' do
        it 'raises an error' do
          allow(Abt::GitConfig).to receive(:local_available?).and_return false

          config = Abt::GitConfig.new(scope: 'local')

          expect { config['key'] }.to raise_error(StandardError)
        end
      end
    end

    describe '#[]=' do
      it 'uses the specified scope and prefixes the key with the namespace' do
        config = Abt::GitConfig.new(namespace: 'namespace', scope: 'global')

        allow(config).to receive(:`).and_return('')

        config['key'] = 'value'

        expect(config).to(
          have_received(:`).with('git config --global --replace-all "namespace.key" "value"')
        )
      end

      context 'when value is nil' do
        it 'unsets the key' do
          config = Abt::GitConfig.new

          allow(config).to receive(:`).and_return('')

          config['key'] = nil

          expect(config).to have_received(:`).with('git config --local --unset "key"')
        end
      end

      context 'when value is not nil' do
        it 'sets the key and returns the value' do
          config = Abt::GitConfig.new

          allow(config).to receive(:`)

          expect(config['key'] = 'value').to eq('value')
          expect(config).to have_received(:`).with('git config --local --replace-all "key" "value"')
        end
      end

      context 'when local scope is not available' do
        it 'raises an error' do
          allow(Abt::GitConfig).to receive(:local_available?).and_return false

          config = Abt::GitConfig.new(scope: 'local')

          expect { config['key'] = 'value' }.to raise_error(StandardError)
        end
      end
    end

    describe '#full_keys' do
      it 'gets all keys in the scope prefixed with the namespace' do
        config = Abt::GitConfig.new(namespace: 'namespace', scope: 'global')

        allow(config).to receive(:`).and_return([
          'namespace.key1',
          'namespace.key2'
        ].join("\n"))

        expect(config.full_keys).to eq(['namespace.key1', 'namespace.key2'])
        expect(config).to(
          have_received(:`).with('git config --global --get-regexp --name-only ^namespace')
        )
      end

      context 'when local scope is not available' do
        it 'raises an error' do
          allow(Abt::GitConfig).to receive(:local_available?).and_return false

          config = Abt::GitConfig.new(scope: 'local')

          expect { config.full_keys }.to raise_error(StandardError)
        end
      end
    end

    describe '#keys' do
      it 'returns the same keys as #full_keys but without the namespace prefix' do
        config = Abt::GitConfig.new(namespace: 'namespace')

        allow(config).to receive(:full_keys).and_return(['namespace.key1', 'namespace.key2'])

        expect(config.keys).to eq(%w[key1 key2])
      end
    end

    describe '#local' do
      context 'when scope is local' do
        it 'returns itself' do
          config = Abt::GitConfig.new(scope: 'local')
          expect(config.local).to be(config)
        end
      end

      context 'when scope is global' do
        it 'returns another config object with same namespace but global scope' do
          config = Abt::GitConfig.new(scope: 'global', namespace: 'namespace')
          expect(config.local).not_to be(config)
          expect(config.local.scope).to eq('local')
          expect(config.local.namespace).to eq('namespace')
        end
      end
    end

    describe '#global' do
      context 'when scope is global' do
        it 'returns itself' do
          config = Abt::GitConfig.new(scope: 'global')
          expect(config.global).to be(config)
        end
      end

      context 'when scope is local' do
        it 'returns another config object with same namespace but local scope' do
          config = Abt::GitConfig.new(scope: 'local', namespace: 'namespace')
          expect(config.global).not_to be(config)
          expect(config.global.scope).to eq('global')
          expect(config.global.namespace).to eq('namespace')
        end
      end
    end
  end
end
