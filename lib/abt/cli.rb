# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/cli/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli
    class AbortError < StandardError; end

    include Dialogs
    include Io

    attr_reader :command, :args, :input, :output, :err_output

    def initialize(argv: ARGV, input: STDIN, output: STDOUT, err_output: STDERR)
      (@command, *@args) = argv

      @input = input
      @output = output
      @err_output = err_output

      @args += args_from_stdin unless input.isatty # Add piped arguments
    end

    def perform
      handle_global_commands!

      abort('No provider arguments') if args.empty?

      process_providers
    end

    def print_provider_command(provider, arg_str, description)
      puts "#{provider}:#{arg_str} # #{description}"
    end

    private

    def handle_global_commands! # rubocop:disable Metrics/MethodLength
      case command
      when nil
        warn("No command specified\n\n")
        puts(Abt::Docs::Cli.content)
        exit
      when '--help', '-h', 'help', 'commands'
        puts(Abt::Docs::Cli.content)
        exit
      when 'help-md'
        puts(Abt::Docs::Markdown.content)
        exit
      when '--version', '-v', 'version'
        puts(Abt::VERSION)
        exit
      end
    end

    def args_from_stdin
      input = STDIN.read

      return [] if input.nil?

      input.split("\n").map do |line|
        line.split(' # ').first # Exclude comment part of piped input lines
      end
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

      warn 'No matching providers found for command' if used_providers.empty?
    end

    def process_provider_command(provider_name, command_name, arg_str)
      provider = Abt.provider_module(provider_name)
      return false if provider.nil?

      command = provider.command_class(command_name)
      return false if command.nil?

      if output.isatty
        warn "===== #{command_name} #{provider_name}#{arg_str.nil? ? '' : ":#{arg_str}"} =====".upcase
      end

      command.new(arg_str: arg_str, cli: self).call
      true
    end
  end
end
