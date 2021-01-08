# frozen_string_literal: true

module Abt
  module Providers
    class Harvest
      COMMANDS = {}.freeze

      attr_reader :args

      def initialize(args)
        @args = args
      end

      def call
        first_arg = args.shift
        args.first.sub(/^harvest:/, '')

        raise NotImplementedError if first_arg.nil?

        process_command(first_arg, args)
      end

      def process_command(command, args)
        inflector = Dry::Inflector.new

        command_class_name = inflector.camelize(inflector.underscore(command))
        command = self.class.const_get command_class_name
        command.new(*args).call
      end

      Dir.glob("#{__dir__}/harvest/*.rb").sort.each do |file|
        require file
      end
    end
  end
end
