# frozen_string_literal: true

module Abt
  class DirectoryConfig < Hash
    def initialize
      super
      merge!(YAML.load_file(config_file_path)) if config_file_path
    end

    private

    def config_file_path
      dir = Dir.pwd

      until File.exist?(File.join(dir, ".abt.yml"))
        next_dir = File.expand_path("..", dir)
        return if next_dir == dir

        dir = next_dir
      end

      File.join(dir, ".abt.yml")
    end
  end
end
