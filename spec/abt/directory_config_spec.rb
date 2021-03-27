# frozen_string_literal: true

RSpec.describe Abt::DirectoryConfig, :directory_config do
  it "contains file values" do
    Dir.mktmpdir do |git_root|
      Open3.popen3("git init #{git_root}") do |_i, _o, _e, thread|
        thread.join
      end

      abt_file = File.new(File.join(git_root, ".abt.yml"), "w")
      abt_file.write(<<~YML)
        ---
        outer_key:
          inner_key: value
      YML
      abt_file.close

      sub_dir = File.join(git_root, "inner_dir")
      Dir.mkdir(sub_dir)

      Dir.chdir(sub_dir) do
        config_file = Abt::DirectoryConfig.new
        expect(config_file).not_to(be_empty)
        expect(config_file.dig("outer_key", "inner_key")).to eq("value")
      end
    end
  end

  context "when there's no config file" do
    it "is empty" do
      Dir.mktmpdir do |git_root|
        Open3.popen3("git init #{git_root}") do |_i, _o, _e, thread|
          thread.join
        end

        Dir.chdir(git_root) do
          config_file = Abt::DirectoryConfig.new
          expect(config_file).to be_empty
        end
      end
    end
  end

  context "when outside git repository" do
    it "is empty" do
      Dir.mktmpdir do |directory|
        Dir.chdir(directory) do
          config_file = Abt::DirectoryConfig.new
          expect(config_file).to be_empty
        end
      end
    end
  end

  describe "save!" do
    it "saves changes to the config file" do
      Dir.mktmpdir do |git_root|
        Open3.popen3("git init #{git_root}") do |_i, _o, _e, thread|
          thread.join
        end

        abt_file_path = File.join(git_root, ".abt.yml")
        abt_file = File.new(abt_file_path, "w")
        abt_file.write(<<~YML)
          ---
          outer_key:
            inner_key: value
        YML
        abt_file.close

        config_file = nil
        Dir.chdir(git_root) { config_file = Abt::DirectoryConfig.new }

        config_file["outer_key2"] = { "inner_key2" => "value2" }
        config_file.save!

        updated_abt_file = File.open(abt_file_path)
        expect(updated_abt_file.read).to eq(<<~YML)
          ---
          outer_key:
            inner_key: value
          outer_key2:
            inner_key2: value2
        YML
      end
    end
  end
end
