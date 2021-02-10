# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/cli/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli
    class Abort < StandardError; end
    class Exit < StandardError; end

    attr_reader :command, :provider_arguments, :input, :output, :err_output, :prompt

    def initialize(argv: ARGV, input: STDIN, output: STDOUT, err_output: STDERR)
      (@command, *remaining_args) = argv
      @input = input
      @output = output
      @err_output = err_output
      @prompt = Abt::Cli::Prompt.new(output: err_output)

      @provider_arguments = ArgumentsParser.new(sanitized_piped_args + remaining_args).parse
    end

    def perform
      return if handle_global_commands!

      abort('No provider arguments') if provider_arguments.empty?

      process_providers
    end

    def print_provider_command(provider, path, description = nil)
      command = "#{provider}:#{path}"
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

    def handle_global_commands!
      case command
      when nil
        warn("No command specified\n\n")
        puts(Abt::Docs::Cli.help)
        true
      when '--version', '-v', 'version'
        puts(Abt::VERSION)
        true
      when '--help', '-h', 'help'
        puts(Abt::Docs::Cli.help)
        true
      when 'commands'
        puts(Abt::Docs::Cli.commands)
        true
      when 'examples'
        puts(Abt::Docs::Cli.examples)
        true
      when 'readme'
        puts(Abt::Docs::Markdown.readme)
        true
      else
        false
      end
    end

    def sanitized_piped_args
      return [] if input.isatty

      @sanitized_piped_args ||= begin
        input_string = input.read.strip

        abort 'No input from pipe' if input_string.nil? || input_string.empty?

        # Exclude comment part of piped input lines
        lines_without_comments = input_string.lines.map do |line|
          line.split(' # ').first
        end

        # Allow multiple provider arguments on a single piped input line
        joined_lines = lines_without_comments.join(' ').strip
        joined_lines.split(/\s+/)
      end
    end

    def process_providers
      used_schemes = []
      provider_arguments.each do |provider_argument|
        (scheme, path) = provider_argument.uri.split(':')

        if used_schemes.include?(scheme)
          warn "Dropping command for already used provider: #{provider_argument.uri}"
          next
        end

        command_class = get_command_class(scheme, command)
        next if command_class.nil?

        print_command(command, scheme, path) if output.isatty
        begin
          command_class.new(path: path, cli: self, flags: provider_argument.flags).perform
        rescue Exit => e
          puts e.message
        end

        used_schemes << scheme
      end

      abort 'No matching providers found for command' if used_schemes.empty? && output.isatty
    end

    def get_command_class(provider_name, command_name)
      provider = Abt.provider_module(provider_name)
      return nil if provider.nil?

      provider.command_class(command_name)
    end

    def print_command(name, provider, path)
      warn "===== #{name} #{provider}#{path.nil? ? '' : ":#{path}"} =====".upcase
    end
  end
end
