# frozen_string_literal: true

module CommandHelpers
  def null_stream
    stream = StringIO.new
    allow(stream).to receive(:isatty).and_return(false)
    stream
  end

  def stub_command_output(scheme, command, output_string)
    provider_class = Abt.scheme_provider(scheme)

    raise ArgumentError, "stub_command only works with existing schemes" unless provider_class

    allow(provider_class).to receive(:command_class).and_call_original
    allow(provider_class).to receive(:command_class)
      .with(command)
      .and_return(command_class_stub(output_string))
  end

  def command_class_stub(output_string)
    Class.new do
      @@output_string = output_string # rubocop:disable Style/ClassVars

      def initialize(cli:, **)
        @cli = cli
      end

      def perform
        @cli.puts @@output_string
      end
    end
  end
end
