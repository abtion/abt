# frozen_string_literal: true

require "tmpdir"

RSpec.describe Abt::DirectoryConfig do
  it "contains file values" do
    Dir.mktmpdir do |outer_directory|
      abt_file = File.new(File.join(outer_directory, ".abt.yml"), "w")
      abt_file.write(<<~YML)
        outer_key:
          inner_key: 'value'
      YML
      abt_file.close

      inner_directory = File.join(outer_directory, "inner_dir")
      Dir.mkdir(inner_directory)

      allow(Dir).to receive(:pwd).and_return(inner_directory)

      config_file = Abt::DirectoryConfig.new

      expect(config_file).not_to(be_empty)
      expect(config_file.dig("outer_key", "inner_key")).to eq("value")
    end
  end

  context "when config file is not present" do
    it "is empty" do
      Dir.mktmpdir do |directory|
        allow(Dir).to receive(:pwd).and_return(directory)

        config_file = Abt::DirectoryConfig.new

        expect(config_file).to be_empty
      end
    end
  end
end
