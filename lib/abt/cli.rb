# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/cli/**/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli
    class Abort < StandardError; end

    class Exit < StandardError; end

    def self.global_command_names
      GlobalCommands.constants.sort.map { |constant_name| Helpers.const_to_command(constant_name) }
    end

    def self.global_command_class(name)
      name = "help" if [nil, "-h", "--help"].include?(name)
      name = "version" if ["-v", "--version"].include?(name)

      const_name = Helpers.command_to_const(name)
      return unless GlobalCommands.const_defined?(const_name)

      GlobalCommands.const_get(const_name)
    end

    attr_reader :command, :aris, :input, :output, :err_output, :prompt

    def initialize(argv: ARGV, input: STDIN, output: STDOUT, err_output: STDERR)
      (@command, *remaining_args) = argv
      @input = input
      @output = output
      @err_output = err_output
      @prompt = Abt::Cli::Prompt.new(output: err_output)
      @aris = ArgumentsParser.new(sanitized_piped_args + remaining_args).parse
    end

    def perform
      if command.nil?
        warn("No command specified, printing help\n\n")
        @command = "help"
      end

      if global_command?
        process_global_command
      else
        process_aris
      end
    end

    def print_ari(scheme, path, description = nil)
      command = "#{scheme}:#{path}"
      command += " # #{description}" unless description.nil?
      output.puts command
    end

    def warn(*args)
      err_output.puts(*args)
    end

    def puts(*args)
      output.puts(*args)
    end

    def print(*args)
      output.print(*args)
    end

    def abort(message)
      raise Abort, message
    end

    def exit_with_message(message)
      raise Exit, message
    end

    private

    def global_command?
      return true if aris.empty?
      return true if aris.first.scheme.nil?

      false
    end

    def process_global_command
      command_class = self.class.global_command_class(command)

      if command_class.nil?
        abort("No such global command: #{command}, perhaps you forgot to add an ARI?")
      end

      begin
        ari = aris.first || Abt::Ari.new
        command_class.new(cli: self, ari: ari).perform
      rescue Exit => e
        puts e.message
      end
    end

    def sanitized_piped_args
      return [] if input.isatty

      @sanitized_piped_args ||= begin
        input_string = input.read.strip

        abort("No input from pipe") if input_string.nil? || input_string.empty?

        # Exclude comment part of piped input lines
        lines_without_comments = input_string.lines.map do |line|
          line.split(" # ").first
        end

        # Allow multiple ARIs on a single piped input line
        # TODO: Force the user to pick a single ARI
        joined_lines = lines_without_comments.join(" ").strip
        joined_lines.split(/\s+/)
      end
    end

    def process_aris
      used_schemes = []

      aris.each do |ari|
        if used_schemes.include?(ari.scheme)
          warn("Dropping command for already used scheme: #{ari}")
          next
        end

        command_class = get_command_class(ari.scheme)
        next if command_class.nil?

        print_command(command, ari) if output.isatty
        begin
          command_class.new(ari: ari, cli: self).perform
        rescue Exit => e
          puts e.message
        end

        used_schemes << ari.scheme
      end

      return unless used_schemes.empty? && output.isatty

      abort("No providers found for command and ARI(s)")
    end

    def get_command_class(scheme)
      provider = Abt.scheme_provider(scheme)
      return nil if provider.nil?

      provider.command_class(command)
    end

    def print_command(name, ari)
      warn("===== #{name.upcase} #{ari} =====")
    end
  end
end
