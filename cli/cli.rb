# frozen_string_literal: true

module Abt
  class Cli
    GLOBAL_COMMANDS = %w[global-init init start stop finalize].freeze

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def perform
      first_arg = args.shift

      raise NotImplementedError if first_arg.nil?

      if GLOBAL_COMMANDS.include?(first_arg)
        method(first_arg).call(args)
      else
        process_provider_command(first_arg, args)
      end
    end

    def start(args)
      args.each do |provider_args|
        (provider, command_args) = provider_args.split(':')
        process_provider_command(provider, ['start', command_args])
      end
    end

    def process_provider_command(provider, args)
      inflector = Dry::Inflector.new

      provider_class_name = inflector.camelize(provider)
      provider = Abt::Providers.const_get provider_class_name
      provider.new(args).call
    end

    def process_global_command(_args)
      raise NotImplementedError
    end
  end
end
