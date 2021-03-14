# frozen_string_literal: true

RSpec.describe Abt::Providers::Git::Commands::Branch do
  def thread_double(success)
    thread_double = instance_double(Thread)
    allow(thread_double).to receive_message_chain(:value, success?: success)
    thread_double
  end

  it "switches to the branch with the branch name provided a by compatible ARI" do
    stub_command_output("asana", "branch-name", "branch-name")

    allow(Open3).to receive(:popen3).with("git switch branch-name").and_yield(nil, nil, nil,
                                                                              thread_double(true))

    err_output = StringIO.new
    cli = Abt::Cli.new(argv: %w[branch git asana], input: null_tty, err_output: err_output, output: null_tty)
    cli.perform

    expect(Open3).to have_received(:popen3).with("git switch branch-name")

    expected_output = <<~TXT
      ===== BRANCH git =====
      Switched to branch-name
    TXT

    expect(err_output.string).to eq(expected_output)
  end

  context "when the branch does not exist" do
    it "allows lets the user create the branch" do
      stub_command_output("asana", "branch-name", "branch-name")

      # Mock failed switch call
      allow(Open3).to receive(:popen3).with("git switch branch-name").and_yield(nil, nil, nil,
                                                                                thread_double(false))

      # Mock successful create and switch call
      allow(Open3).to receive(:popen3).with("git switch -c branch-name").and_yield(nil, nil, nil,
                                                                                   thread_double(true))

      input = QueueIO.new
      err_output = QueueIO.new

      thr = Thread.new do
        cli = Abt::Cli.new(argv: %w[branch git asana], input: input, err_output: err_output, output: null_tty)
        allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

        cli.perform
      end

      expect(err_output.gets).to eq("===== BRANCH git =====\n")
      expect(err_output.gets).to eq("No such branch: branch-name\n")
      expect(err_output.gets).to eq("Create branch?\n")
      expect(err_output.gets).to eq("(y / n): ")

      input.puts("y")

      expect(err_output.gets).to eq("Switched to branch-name\n")

      thr.join
    end

    context "when user declines to create the branch" do
      it "does not create the branch" do
        stub_command_output("asana", "branch-name", "branch-name")

        # Mock failed switch call
        allow(Open3).to receive(:popen3).with("git switch branch-name").and_yield(nil, nil, nil,
                                                                                  thread_double(false))

        input = QueueIO.new
        err_output = QueueIO.new

        thr = Thread.new do
          cli = Abt::Cli.new(argv: %w[branch git asana], input: input, err_output: err_output, output: null_tty)
          allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

          cli.perform
        end
        thr.report_on_exception = false # We expect an exception and we don't want it printed

        expect(err_output.gets).to eq("===== BRANCH git =====\n")
        expect(err_output.gets).to eq("No such branch: branch-name\n")
        expect(err_output.gets).to eq("Create branch?\n")
        expect(err_output.gets).to eq("(y / n): ")

        input.puts("n")

        expect { thr.join }.to raise_error(Abt::Cli::Abort, "Aborting")
      end
    end
  end

  context "when no additional ARI was provided" do
    it "aborts with a correct error message" do
      err_output = StringIO.new
      cli = Abt::Cli.new(argv: %w[branch git], input: null_tty, err_output: err_output)

      expect { cli.perform }.to(
        raise_error(Abt::Cli::Abort,
                    "You must provide an additional ARI that responds to: branch-name. E.g., asana")
      )
    end
  end

  context "when none of the provided ARIs responds to branch-name" do
    it "aborts with a correct error message" do
      err_output = StringIO.new
      cli = Abt::Cli.new(argv: %w[branch git invalid-provider], input: null_tty, err_output: err_output)

      expect { cli.perform }.to(
        raise_error do |error|
          expect(error).to be_an(Abt::Cli::Abort)
          expect(error.message).to include("None of the specified ARIs responded to `branch-name`.")
        end
      )
    end
  end

  context "when multiple of the provided ARIs responds to branch-name" do
    it "aborts with a correct error message" do
      stub_command_output("asana", "branch-name", "asana-branch-name")
      stub_command_output("devops", "branch-name", "devops-branch-name")

      err_output = StringIO.new
      cli = Abt::Cli.new(argv: %w[branch git asana devops], input: null_tty, err_output: err_output)

      expect { cli.perform }.to(
        raise_error do |error|
          expect(error).to be_an(Abt::Cli::Abort)
          expect(error.message).to(
            include("Got branch names from multiple ARIs, only one is supported")
          )
        end
      )
    end
  end
end
