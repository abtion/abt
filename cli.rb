# frozen_string_literal: true

module Abt
  class Cli
    attr_reader :command, :args

    def initialize(argv)
      (@command, *@args) = argv

      @args += args_from_stdin unless STDIN.isatty # Add piped arguments
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

    def prompt(question)
      STDERR.print "#{question}: "
      read_user_input.strip
    end

    def prompt_choice(text, options, allow_back_option = false)
      if options.one?
        warn "Selected: #{options.first['name']}"
        return options.first
      end

      warn "#{text}:"

      options.each_with_index do |option, index|
        warn "(#{index + 1}) #{option['name']}"
      end

      loop do
        STDERR.print "(1-#{options.length}#{allow_back_option ? ', q: back' : ''}): "

        input = read_user_input.strip

        return nil if allow_back_option && input == 'q'

        option_number = input.to_i
        abort 'Invalid selection' if option_number <= 0 || option_number > options.length

        option = options[option_number - 1]

        warn "Selected: (#{option_number}) #{option['name']}"
        return option
      end
    end

    def print_provider_command(provider, arg_str, description)
      puts "#{provider}:#{arg_str} # #{description}"
    end

    private

    def read_user_input
      open('/dev/tty', &:gets)
    end

    def args_from_stdin
      input = STDIN.read

      return [] if input.nil?

      input.split("\n").map do |line|
        # Only include part before first space
        line.split(' # ').first
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
