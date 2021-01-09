# frozen_string_literal: true

module Abt
  class Cli
    attr_reader :command, :args

    def initialize(argv)
      (@command, *@args) = argv
    end

    def perform(command = @command, args = @args)
      abort('No command specified') if command.nil?
      abort('No provider arguments') if args.empty?

      args.each do |provider_args|
        (provider, arg_str) = provider_args.split(':')
        process_provider_command(provider, command, arg_str)
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

    def process_global_command(_args)
      raise NotImplementedError
    end
  end
end
