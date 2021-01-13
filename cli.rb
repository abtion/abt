# frozen_string_literal: true

require 'stringio'

module Abt
  class Cli
    attr_reader :command, :args

    def initialize(argv)
      (@command, *@args) = argv

      @args += args_from_stdin unless STDIN.isatty # Add piped arguments
    end

    def perform(command = @command, args = @args)
      if command.nil?
        warn('No command specified')
        warn ''
        print_help
      elsif ['--help', '-h', 'help', 'commands'].include?(command)
        print_help
      elsif command === 'help-md'
        print_help_md
      end
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

    def print_help
      puts help_text
      exit
    end

    def print_help_md
      puts help_md
      exit
    end

    def help_text
      text = StringIO.new

      text.puts <<~TXT
        Usage: abt <command> [<provider:arguments>...]

        Multiple providers and arguments can be passed, e.g.:
          `abt init asana harvest`
          `abt pick-task asana harvest`
          `abt start asana harvest`
          `abt clear asana harvest`

        Command output can be piped, e.g.:
          `abt tasks asana | grep -i <name of task>`
          `abt tasks asana | grep -i <name of task> | abt start`

        Available commands:
      TXT

      Abt::Providers.constants.sort.each_with_index do |provider_name, index|
        text.puts '' unless index.zero?
        text.puts commandize(provider_name)

        provider_class = Abt::Providers.const_get(provider_name)
        command_texts = []
        provider_class.constants.sort.each do |command_name|
          command_class = provider_class.const_get(command_name)

          if command_class.respond_to? :command
            command_texts.push([command_class.command, command_class.description])
          end
        end

        max_length = command_texts.map(&:first).map(&:length).max
        command_texts.each do |(command, description)|
          text.puts("  #{command.ljust(max_length)} # #{description}")
        end
      end

      text.string.strip!
    end

    def help_md
      text = StringIO.new

      text.puts <<~MD
        # Abt
        This readme was generated with `abt help-md > README.md`

        ## Usage
        `abt <command> [<provider:arguments>...]`

        Multiple providers and arguments can be passed, e.g.:
        - `abt init asana harvest`
        - `abt pick-task asana harvest`
        - `abt start asana harvest`
        - `abt clear asana harvest`

        Command output can be piped, e.g.:
        - `abt tasks asana | grep -i <name of task>`
        - `abt tasks asana | grep -i <name of task> | abt start`

        ## Available commands:
      MD

      Abt::Providers.constants.sort.each_with_index do |provider_name, index|
        text.puts '' unless index.zero?
        text.puts "### #{provider_name}"
        text.puts '| Command | Description |'
        text.puts '| :------ | :---------- |'

        provider_class = Abt::Providers.const_get(provider_name)
        command_texts = []
        provider_class.constants.sort.each do |command_name|
          command_class = provider_class.const_get(command_name)

          if command_class.respond_to? :command
            command_texts.push([command_class.command, command_class.description])
          end
        end

        max_length = command_texts.map(&:first).map(&:length).max
        command_texts.each do |(command, description)|
          text.puts("| `#{command.ljust(max_length)}` | #{description} |")
        end
      end

      text.string.strip!
    end

    def commandize(string)
      string = string.to_s
      string[0] = string[0].downcase
      string.gsub(/([A-Z])/, '-\1').downcase
    end

    def read_user_input
      open('/dev/tty', &:gets)
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
