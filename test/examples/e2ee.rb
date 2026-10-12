# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"
require "tempfile"

require "async/matrix/client_context"

# Every encryption example, run against the homeserver the suite brought up.
#
# The examples are where the shape of the encryption layer is worked out before it is built, so they are the first thing to go stale when a name changes. Running them is what notices.
#
# Each one finishes with a sync loop which never returns, so `fixtures/async/matrix/example_once.rb` is required ahead of it: the loop runs once and the process exits. So an example is run to the end rather than interrupted part way, and the body of the loop is covered along with the setup above it.
describe "examples/e2ee" do
  include Async::Matrix::ClientContext

  ROOT = File.expand_path("../..", __dir__)

  # What makes the sync loop run once rather than forever.
  ONCE = File.join(ROOT, "fixtures", "async", "matrix", "example_once.rb")

  # Where the examples are.
  EXAMPLES = Dir.glob(File.join(ROOT, "examples", "e2ee", "*.rb")).sort

  # Far longer than an example needs, so that only a hang reaches it.
  TIMEOUT = 60

  # One account for all of them: each login makes a device of its own, and registering one user per example would be a request for nothing.
  USERNAME = "example-#{SecureRandom.hex(6)}"

  # Run one example to the end, and say how it went.
  #
  # @parameter path [String] the example to run.
  # @returns [Hash] the status, and whatever it wrote.
  def run_example(path)
    output = Tempfile.new("example")

    environment = {
      "MATRIX_HOMESERVER" => Async::Matrix::HOMESERVER,
      "MATRIX_USER" => USERNAME,
      "MATRIX_PASSWORD" => Async::Matrix::TEST_PASSWORD,
      "CONSOLE_LEVEL" => ENV.fetch("CONSOLE_LEVEL", "warn"),
    }

    # Its own process group, so that a hang can be stopped whole.
    pid = Process.spawn(environment, RbConfig.ruby, "-r#{ONCE}", path, out: output.path, err: output.path, pgroup: true)

    status = self.wait_for(pid)

    output.rewind

    {status: status, output: output.read}.tap do
      output.close!
    end
  end

  # @parameter pid [Integer] the process to wait for.
  # @returns [Process::Status | nil] how it ended, or nil if it had to be stopped.
  def wait_for(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT
    finished = nil

    while finished.nil? and Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      _, finished = Process.waitpid2(pid, Process::WNOHANG)

      if finished.nil?
        sleep(0.05)
      end
    end

    # Never finished, so the whole group is stopped rather than left behind.
    if finished.nil?
      Process.kill("TERM", -Process.getpgid(pid))
      Process.waitpid(pid)
    end

    finished
  end

  # The account has to exist before an example tries to log into it.
  let(:registered) {self.account(USERNAME)}

  EXAMPLES.each do |path|
    name = File.basename(path)

    with name do
      it "runs against the homeserver" do
        registered

        result = self.run_example(path)

        case result
        in {status: Process::Status => status, output: String => output}
          # Anything but a clean exit is the example and the library no longer agreeing.
          unless status.success?
            raise "#{name} exited #{status.exitstatus}:\n\n#{output.lines.last(24).join}"
          end

          expect(status.success?).to be == true

        # Never finished, so something in it is waiting on what will not arrive.
        in {status: nil, output: String => output}
          raise "#{name} did not finish within #{TIMEOUT}s:\n\n#{output.lines.last(24).join}"
        end
      end
    end
  end
end
