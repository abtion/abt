# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/cli/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli # rubocop:disable Metrics/ClassLength
    class Abort < StandardError; end

    class Exit < StandardError; end

    attr_reader :command, :remaining_args, :input, :output, :err_output, :prompt

    def initialize(argv: ARGV, input: $stdin, output: $stdout, err_output: $stderr)
      (@command, *@remaining_args) = argv
      @input = input
      @output = output
      @err_output = err_output
      @prompt = Abt::Cli::Prompt.new(output: err_output)
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

    def aris
      @aris ||= ArgumentsParser.new(sanitized_piped_args + remaining_args).parse
    end

    private

    def global_command?
      return true if aris.empty?
      return true if aris.first.scheme.nil?

      false
    end

    def process_global_command
      command_class = GlobalCommands.command_class(command)

      abort("No such global command: #{command}, perhaps you forgot to add an ARI?") if command_class.nil?

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
        lines_without_comments = input_string.lines.map { |line| line.split(" # ").first }

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

        used_schemes << ari.scheme if process_ari(ari)
      end

      return unless used_schemes.empty? && output.isatty

      abort("No providers found for command and ARI(s)")
    end

    def process_ari(ari)
      command_class = get_command_class(ari.scheme)
      return false if command_class.nil?

      print_command(command, ari) if output.isatty
      begin
        command_class.new(ari: ari, cli: self).perform
      rescue Exit => e
        puts e.message
      end

      true
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
