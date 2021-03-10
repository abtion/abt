# frozen_string_literal: true

RSpec.describe Abt::GitConfig do
  describe "#initialize" do
    it "sets namespace and scope" do
      config = Abt::GitConfig.new("local", "namespace")

      expect(config.namespace).to be("namespace")
      expect(config.scope).to be("local")
    end

    it 'only allows namespaces "local" and "global"' do
      expect { Abt::GitConfig.new("local") }.not_to(raise_error)
      expect { Abt::GitConfig.new("global") }.not_to(raise_error)
      expect { Abt::GitConfig.new("testing") }.to raise_error(ArgumentError)
    end
  end

  describe "instance" do
    describe "#[]" do
      it "uses the specified scope and prefixes the key with the namespace" do
        config = Abt::GitConfig.new("global", "namespace")

        allow(config).to receive(:available?).and_return(true)
        allow(config).to receive(:`).and_return("")

        config["key"]

        expect(config).to have_received(:`).with('git config --global --get "namespace.key"')
      end

      context "when git config outputs a value" do
        it "strips and returns the value" do
          config = Abt::GitConfig.new

          allow(config).to receive(:available?).and_return(true)
          allow(config).to receive(:`).and_return("a value\n")

          expect(config["key"]).to eq("a value")
        end
      end

      context "when git config outputs nothing" do
        it "returns nil" do
          config = Abt::GitConfig.new

          allow(config).to receive(:available?).and_return(true)
          allow(config).to receive(:`).and_return("")

          expect(config["key"]).to be_nil
        end
      end

      context "when scope is not available" do
        it "raises an error" do
          config = Abt::GitConfig.new

          allow(config).to receive(:available?).and_return(false)

          expect { config["key"] }.to raise_error(StandardError)
        end
      end
    end

    describe "#[]=" do
      it "uses the specified scope and prefixes the key with the namespace" do
        config = Abt::GitConfig.new("global", "namespace")

        allow(config).to receive(:available?).and_return(true)
        allow(config).to receive(:`).and_return("")

        config["key"] = "value"

        expect(config).to(
          have_received(:`).with('git config --global --replace-all "namespace.key" "value"')
        )
      end

      context "when value is nil" do
        it "unsets the key" do
          config = Abt::GitConfig.new

          allow(config).to receive(:available?).and_return(true)
          allow(config).to receive(:`).and_return("")

          config["key"] = nil

          expect(config).to have_received(:`).with('git config --local --unset "key"')
        end
      end

      context "when value is not nil" do
        it "sets the key and returns the value" do
          config = Abt::GitConfig.new

          allow(config).to receive(:available?).and_return(true)
          allow(config).to receive(:`)

          expect(config["key"] = "value").to eq("value")
          expect(config).to have_received(:`).with('git config --local --replace-all "key" "value"')
        end
      end

      context "when scope is not available" do
        it "raises an error" do
          config = Abt::GitConfig.new
          allow(config).to receive(:available?).and_return(false)

          expect { config["key"] = "value" }.to raise_error(StandardError)
        end
      end
    end

    describe "#full_keys" do
      it "gets all keys in the scope prefixed with the namespace" do
        config = Abt::GitConfig.new("global", "namespace")

        allow(config).to receive(:available?).and_return(true)
        allow(config).to receive(:`).and_return([
          "namespace.key1",
          "namespace.key2"
        ].join("\n"))

        expect(config.full_keys).to eq(["namespace.key1", "namespace.key2"])
        expect(config).to(
          have_received(:`).with("git config --global --get-regexp --name-only ^namespace")
        )
      end

      context "when scope is not available" do
        it "raises an error" do
          config = Abt::GitConfig.new
          allow(config).to receive(:available?).and_return(false)

          expect { config.full_keys }.to raise_error(StandardError)
        end
      end
    end

    describe "#keys" do
      it "returns the same keys as #full_keys but without the namespace prefix" do
        config = Abt::GitConfig.new("local", "namespace")

        allow(config).to receive(:available?).and_return(true)
        allow(config).to receive(:full_keys).and_return(["namespace.key1", "namespace.key2"])

        expect(config.keys).to eq(%w[key1 key2])
      end
    end

    describe "#clear" do
      it "sets all keys to nil" do
        config = Abt::GitConfig.new("local", "namespace")

        allow(config).to receive(:available?).and_return(true)
        allow(config).to receive(:keys).and_return(%w[key1 key2])
        allow(config).to receive(:[]=)

        config.clear

        expect(config).to have_received(:[]=).ordered.with("key1", nil)
        expect(config).to have_received(:[]=).ordered.with("key2", nil)
      end

      context "when an output is specified" do
        it "logs the deleted keys" do
          output = StringIO.new
          config = Abt::GitConfig.new("local", "namespace")

          allow(config).to receive(:available?).and_return(true)
          allow(config).to receive(:keys).and_return(%w[key1 key2])
          allow(config).to receive(:[]=)

          config.clear(output: output)

          expect(output.string).to eq(
            <<~TXT
              Clearing local: namespace.key1
              Clearing local: namespace.key2
            TXT
          )
        end
      end

      context "when namespace is empty" do
        it "raises an UnsafeNamespaceError" do
          config = Abt::GitConfig.new("local", "")
          allow(config).to receive(:available?).and_return(true)

          expect { config.clear }.to raise_error(Abt::GitConfig::UnsafeNamespaceError)
        end
      end
    end

    describe "#available?" do
      it 'calls "git config --scope -l"' do
        config = Abt::GitConfig.new("local")

        system_call = nil
        allow(Open3).to receive(:popen3) do |received_system_call|
          system_call = received_system_call
        end

        config.available?

        expect(system_call).to eq("git config --local -l")
      end

      context "when command is successful" do
        it "is true" do
          config = Abt::GitConfig.new
          allow(config).to receive(:availability_check_call).and_return("true")

          expect(config.available?).to be(true)
        end
      end

      context "when command is unsuccessful" do
        it "is false" do
          config = Abt::GitConfig.new
          allow(config).to receive(:availability_check_call).and_return("false")

          expect(config.available?).to be(false)
        end
      end
    end
  end
end
