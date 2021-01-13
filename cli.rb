# frozen_string_literal: true

Dir.glob("#{Abt::ROOT}/cli/*.rb").sort.each do |file|
  require file
end

module Abt
  class Cli
    include Dialogs
    include Help

    attr_reader :command, :args

    def initialize(argv)
      (@command, *@args) = argv

      @args += args_from_stdin unless STDIN.isatty # Add piped arguments
    end

    def perform(command = @command, args = @args)
      handle_global_commands!

      abort('No provider arguments') if args.empty?

      used_providers = []
      args.each do |provider_args|
        (provider, arg_str) = provider_args.split(':')

        if used_providers.include?(provider)
          warn "Dropping command for already used provider: #{provider_args}"
          next
        end
        used_providers << provider

        process_provider_command(provider, command, arg_str)
      end
    end

    def print_provider_command(provider, arg_str, description)
      puts "#{provider}:#{arg_str} # #{description}"
    end

    private

    def handle_global_commands!
      case command
      when nil
        warn('No command specified')
        warn ''
        puts help_text
        exit
      when '--help', '-h', 'help', 'commands'
        puts help_text
        exit
      when 'help-md'
        puts help_md
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

    def process_provider_command(provider, command, arg_str)
      inflector = Dry::Inflector.new

      provider_class_name = inflector.camelize(inflector.underscore(provider))
      command_class_name = inflector.camelize(inflector.underscore(command))
      provider_class = Abt::Providers.const_get provider_class_name

      return unless provider_class.const_defined? command_class_name

      if STDOUT.isatty
        warn "===== #{command} #{provider}#{arg_str.nil? ? '' : ":#{arg_str}"} =====".upcase
      end

      command = provider_class.const_get command_class_name
      command.new(arg_str: arg_str, cli: self).call
    end
  end
end
