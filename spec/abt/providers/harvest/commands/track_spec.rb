# frozen_string_literal: true

RSpec.describe(Abt::Providers::Harvest::Commands::Track, :harvest) do
  let(:project_id) { "27701618" }
  let(:task_id) { "14628589" }
  let(:user_id) { harvest_credentials["userId"] }
  let(:local_git) { GitConfigMock.new }
  let(:global_git) { GitConfigMock.new(data: harvest_credentials) }

  before do
    allow(Abt::GitConfig).to receive(:new).with("local", "abt.harvest").and_return(local_git)
    allow(Abt::GitConfig).to receive(:new).with("global", "abt.harvest").and_return(global_git)
  end

  it "prompts for a comment and posts a running time entry with correct data" do
    stub_post_time_entry(global_git,
                         project: { id: project_id, name: "Project" },
                         task: { id: task_id, name: "Task 1" })
      .with(body: {
              project_id: project_id,
              task_id: task_id,
              user_id: user_id,
              spent_date: Date.today.iso8601,
              notes: "Note"
            })

    input = QueueIO.new
    err_output = QueueIO.new
    output = QueueIO.new
    argv = ["track", "harvest:#{project_id}/#{task_id}"]

    thr = Thread.new do
      cli = Abt::Cli.new(argv: argv, input: input, err_output: err_output, output: output)
      allow(Abt::Helpers).to receive(:read_user_input) { input.gets.strip }

      cli.perform
    end

    expect(err_output.gets).to eq("===== TRACK harvest:#{project_id}/#{task_id} =====\n")
    expect(err_output.gets).to eq("No external link provided\n")
    expect(err_output.gets).to eq("Fill in comment (optional): ")

    input.puts("Note")

    expect(output.gets).to eq("harvest:27701618/14628589 # Project > Task 1\n")

    thr.join
  end

  context "when --comment flag provided" do
    it "uses the provided value as comment" do
      stub_post_time_entry(global_git,
                           project: { id: project_id, name: "Project" },
                           task: { id: task_id, name: "Task 1" })
        .with(body: hash_including(notes: "Note"))

      output = StringIO.new
      argv = ["track", "harvest:#{project_id}/#{task_id}", "-c", "Note"]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)
      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
    end
  end

  context "when --time flag provided" do
    it "uses the provided value as comment" do
      stub_post_time_entry(global_git,
                           project: { id: project_id, name: "Project" },
                           task: { id: task_id, name: "Task 1" })
        .with(body: hash_including(hours: "1:30"))

      output = StringIO.new
      comment_to_avoid_prompt = ["-c", "Note"]
      argv = ["track", "harvest:#{project_id}/#{task_id}", "-t", "1:30", *comment_to_avoid_prompt]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)
      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
    end
  end

  context "when --set flag provided" do
    it "overrides the current configuration" do
      stub_post_time_entry(global_git,
                           project: { id: project_id, name: "Project" },
                           task: { id: task_id, name: "Task 1" })

      err_output = StringIO.new
      comment_to_avoid_prompt = ["-c", "Note"]
      argv = ["track", "harvest:#{project_id}/#{task_id}", "-s", *comment_to_avoid_prompt]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: null_stream)

      expect(local_git["path"]).to be_nil

      cli.perform

      expect(err_output.string).to include("Current task updated")
      expect(local_git["path"]).to eq("#{project_id}/#{task_id}")
    end
  end

  context "when --since flag provided" do
    it "starts the entry at the specified time" do
      now = Time.now
      now_for_test = Time.new(now.year, now.mon, now.day, 12, 0)
      since_string = "11:30"
      expected_hours = 0.5

      allow(Time).to receive(:now).and_return(now_for_test)

      stub_harvest_request(global_git, :get, "time_entries?is_running=true&page=1&user_id=#{user_id}")
        .to_return(body: '{"time_entries":[],"total_pages":1}')

      stub_post_time_entry(global_git,
                           id: 12_345_678,
                           project: { id: project_id, name: "Project" },
                           task: { id: task_id, name: "Task 1" })
        .with(body: hash_including(hours: expected_hours))

      stub_request(:patch, "https://api.harvestapp.com/v2/time_entries/12345678/restart")
        .with(headers: request_headers_for_git_config(global_git))

      output = StringIO.new
      comment_to_avoid_prompt = ["-c", "Note"]
      flags = ["-i", since_string, *comment_to_avoid_prompt]
      argv = ["track", "harvest:#{project_id}/#{task_id}", *flags]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)
      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
    end

    context "when there's an existing running entry" do
      it "deducts the computed duration from the running entry" do
        now = Time.now
        now_for_test = Time.new(now.year, now.mon, now.day, 12, 0)
        since_string = "11:30"
        expected_hours = 0.5
        running_entry_hours = 1.75
        expected_adjusted_hours = running_entry_hours - expected_hours

        allow(Time).to receive(:now).and_return(now_for_test)

        stub_harvest_request(global_git, :get, "time_entries?is_running=true&page=1&user_id=#{user_id}")
          .to_return(body: Oj.dump({
                                     time_entries: [{ id: "11111", hours: running_entry_hours }],
                                     total_pages: 1
                                   }, mode: :json))

        stub_harvest_request(global_git, :patch, "time_entries/11111")
          .with(body: { hours: expected_adjusted_hours })

        stub_post_time_entry(global_git,
                             id: 12_345_678,
                             project: { id: project_id, name: "Project" },
                             task: { id: task_id, name: "Task 1" })

        stub_request(:patch, "https://api.harvestapp.com/v2/time_entries/12345678/restart")
          .with(headers: request_headers_for_git_config(global_git))

        output = StringIO.new
        err_output = StringIO.new
        comment_to_avoid_prompt = ["-c", "Note"]
        flags = ["-i", since_string, *comment_to_avoid_prompt]
        argv = ["track", "harvest:#{project_id}/#{task_id}", *flags]

        cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: err_output, output: output)
        cli.perform

        expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
        expect(err_output.string).to include("~30 minute(s) subtracted from previous entry")
      end
    end

    context "when provided time is invalid" do
      it "aborts with correct message" do
        flags = ["-i", "12-00"]
        argv = ["track", "harvest:#{project_id}/#{task_id}", *flags]

        cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort, "Invalid time: 12-00, supported formats are: HH:MM, HH:MM:SS")
      end
    end

    context "when provided time is in the future" do
      it "aborts with correct message" do
        now = Time.now
        now_for_test = Time.new(now.year, now.mon, now.day, 12, 0)

        allow(Time).to receive(:now).and_return(now_for_test)

        flags = ["-i", "12:01"]
        argv = ["track", "harvest:#{project_id}/#{task_id}", *flags]

        cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort, 'Specified "since" time (12:01) is in the future')
      end
    end
  end

  context "when --since and --time flags are used together" do
    it "aborts with correct message" do
      flags = ["-i", "12:00", "-t", "1:00"]
      argv = ["track", "harvest:#{project_id}/#{task_id}", *flags]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort, "Flags --time and --since cannot be used together")
    end
  end

  context "when external link compatible ARI provided" do
    it "adds reference data to the time entry" do
      link_data = { notes: "Note", external_reference: { permalink: "link" } }

      stub_command_output("asana", "harvest-time-entry-data", Oj.dump(link_data, mode: :json))

      stub_post_time_entry(global_git,
                           project: { id: project_id, name: "Project" },
                           task: { id: task_id, name: "Task 1" })
        .with(body: hash_including(link_data))

      output = StringIO.new
      argv = ["track", "harvest:#{project_id}/#{task_id}", "asana:1111/2222"]

      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)
      cli.perform

      expect(output.string).to eq("harvest:27701618/14628589 # Project > Task 1\n")
    end

    context "when multiple compatible ARIs" do
      it "aborts with correct message" do
        stub_command_output("asana", "harvest-time-entry-data", "{}")
        stub_command_output("devops", "harvest-time-entry-data", "{}")

        output = StringIO.new
        argv = ["track", "harvest:#{project_id}/#{task_id}", "asana", "devops"]

        cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: output)

        expect do
          cli.perform
        end.to raise_error(Abt::Cli::Abort,
                           "Got reference data from multiple scheme providers, only one is supported at a time")
      end
    end
  end

  context "when request fails" do
    it "aborts with correct error message" do
      stub_request(:post, "https://api.harvestapp.com/v2/time_entries")
        .and_return(status: 422)

      comment_to_avoid_prompt = ["-c", "Note"]
      argv = ["track", "harvest:#{project_id}/#{task_id}", *comment_to_avoid_prompt]
      cli = Abt::Cli.new(argv: argv, input: null_tty, err_output: null_stream, output: null_stream)

      expect { cli.perform }.to raise_error(Abt::Cli::Abort, "Invalid task")
    end
  end

  context "when missing project_id" do
    it "aborts with correct error message" do
      cli = Abt::Cli.new(argv: %w[track harvest], input: null_tty, output: null_stream)

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort, "No current/specified project. Did you forget to run `pick`?")
    end
  end

  context "when missing project_task" do
    it "aborts with correct error message" do
      cli = Abt::Cli.new(argv: %w[track harvest:27701618], input: null_tty, output: null_stream)

      expect do
        cli.perform
      end.to raise_error(Abt::Cli::Abort, "No current/specified task. Did you forget to run `pick`?")
    end
  end
end
