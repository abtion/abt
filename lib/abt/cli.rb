# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/cli/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli
    class AbortError < StandardError; end

    attr_reader :command, :args, :input, :output, :err_output, :prompt

    def initialize(argv: ARGV, input: STDIN, output: STDOUT, err_output: STDERR)
      (@command, *@args) = argv

      @input = input
      @output = output
      @err_output = err_output
      @prompt = Abt::Cli::Prompt.new(output: err_output)

      @args += args_from_input unless input.isatty # Add piped arguments
    end

    def perform
      return if handle_global_commands!

      abort('No provider arguments') if args.empty?

      process_providers
    end

    def print_provider_command(provider, arg_str, description = nil)
      command = "#{provider}:#{arg_str}"
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
      raise AbortError, message
    end

    private

    def handle_global_commands! # rubocop:disable Metrics/MethodLength
      case command
      when nil
        warn("No command specified\n\n")
        puts(Abt::Docs::Cli.content)
        true
      when '--help', '-h', 'help', 'commands'
        puts(Abt::Docs::Cli.content)
        true
      when 'help-md'
        puts(Abt::Docs::Markdown.content)
        true
      when '--version', '-v', 'version'
        puts(Abt::VERSION)
        true
      else
        false
      end
    end

    def args_from_input
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

    def process_providers
      used_providers = []
      args.each do |provider_args|
        (provider, arg_str) = provider_args.split(':')

        if used_providers.include?(provider)
          warn "Dropping command for already used provider: #{provider_args}"
          next
        end

        used_providers << provider if process_provider_command(provider, command, arg_str)
      end

      abort 'No matching providers found for command' if used_providers.empty? && output.isatty
    end

    def process_provider_command(provider_name, command_name, arg_str)
      provider = Abt.provider_module(provider_name)
      return false if provider.nil?

      command = provider.command_class(command_name)
      return false if command.nil?

      print_command(command_name, provider_name, arg_str) if output.isatty

      command.new(arg_str: arg_str, cli: self).call
      true
    end

    def print_command(name, provider, arg_str)
      warn "===== #{name} #{provider}#{arg_str.nil? ? '' : ":#{arg_str}"} =====".upcase
    end
  end
end
