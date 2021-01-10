# frozen_string_literal: true

module Abt
  class Cli
    attr_reader :command, :args

    def initialize(argv)
      (@command, *@args) = argv

      @args += args_from_stdin unless STDIN.isatty # Add piped arguments
      @is_a_tty = STDOUT.isatty ? true : false
    end

    def perform(command = @command, args = @args)
      abort('No command specified') if command.nil?
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

    def prompt(text, options)
      puts "#{text}:"
      options.each_with_index do |option, index|
        puts "(#{index + 1}) #{option['name']}"
      end

      loop do
        print "(1-#{options.length}, q: abort): "

        input = get_user_input.strip

        abort 'Aborted' if input == 'q'

        option_number = input.to_i
        if option_number <= 0 || option_number > options.length
          abort 'Invalid selection'
        end

        option = options[option_number - 1]

        puts "Selected: (#{option_number}) #{option['name']}"
        return option
      end
    end

    def is_a_tty?
      @is_a_tty
    end

    private

    def get_user_input
      unless is_a_tty?
        abort 'Cannot get user input when not running in a tty (did you pipe the call?)'
      end

      open('/dev/tty', &:gets)
    end

    def args_from_stdin
      input = STDIN.read

      return [] if input.nil?

      input.split("\n").map do |line|
        # Only include part before first space
        line[/^([^ ]+)/]
      end
    end

    def process_provider_command(provider, command, arg_str)
      inflector = Dry::Inflector.new

      provider_class_name = inflector.camelize(inflector.underscore(provider))
      command_class_name = inflector.camelize(inflector.underscore(command))
      provider = Abt::Providers.const_get provider_class_name

      return unless provider.const_defined? command_class_name

      command = provider.const_get command_class_name
      command.new(arg_str: arg_str, cli: self).call
    end
  end
end
