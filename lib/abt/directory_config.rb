# frozen_string_literal: true

module Abt
  class DirectoryConfig < Hash
    FILE_NAME = ".abt.yml"

    def initialize
      super
      load! if config_file_path && File.exist?(config_file_path)
    end

    def available?
      !config_file_path.nil?
    end

    def load!
      merge!(YAML.load_file(config_file_path))
    end

    def save!
      raise Abt::Cli::Abort("Configuration files are not available outside of git repositories") unless available?

      config_file = File.open(config_file_path, "w")
      YAML.dump(to_h, config_file)
      config_file.close
    end

    private

    def config_file_path
      @config_file_path ||= begin
        path = nil
        Open3.popen3("git rev-parse --show-toplevel") do |_i, output, _e, thread|
          if thread.value.success?
            repo_root = output.read.chomp
            path = File.join(repo_root, FILE_NAME)
          end
        end
        path
      end
    end
  end
end
