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
# Each one ends in a sync loop which never returns, so a run cannot be waited on: the example is given long enough to get through its setup and into the loop, and what is asserted is that it did not fall over on the way. That is where staleness shows, because the setup is what touches the most of the library.
describe "examples/e2ee" do
  include Async::Matrix::ClientContext

  # Long enough for a few requests against a container on the same machine.
  TIMEOUT = 15

  # Where the examples are, relative to this file.
  EXAMPLES = File.expand_path("../../examples/e2ee", __dir__)

  # Run one example as its own process, and say how it went.
  #
  # @parameter path [String] the example to run.
  # @parameter environment [Hash] what to run it with.
  # @returns [Hash] the status, and whatever it wrote.
  def run_example(path, **environment)
    output = Tempfile.new("example")

    # Its own process group, so that the whole of it can be stopped rather than only the parent.
    pid = Process.spawn(
      environment.transform_keys(&:to_s),
      RbConfig.ruby, path,
      out: output.path, err: output.path, pgroup: true,
    )

    finished = self.wait_for(pid)

    output.rewind

    {status: finished, output: output.read}.tap do
      output.close!
    end
  end

  # Wait for a process to finish, and stop it once it has had long enough.
  #
  # @parameter pid [Integer] the process.
  # @returns [Process::Status | nil] how it ended, or nil if it was still running.
  def wait_for(pid)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + TIMEOUT
    finished = nil

    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      _, status = Process.waitpid2(pid, Process::WNOHANG)

      if status
        finished = status

        break
      end

      sleep(0.1)
    end

    unless finished
      # Still in its sync loop, which is the healthy outcome for an example which never returns.
      Process.kill("TERM", -Process.getpgid(pid))
      Process.waitpid(pid)
    end

    finished
  end

  Dir.glob(File.join(EXAMPLES, "*.rb")).sort.each do |path|
    name = File.basename(path)

    with name do
      # A user of its own, so that one example cannot be upset by what another did.
      let(:example_username) {"example-#{SecureRandom.hex(6)}"}

      # Registered here rather than by the example, because the rig decides how an account comes to exist.
      let(:example_client) {self.account(example_username)}

      it "runs against the homeserver without falling over" do
        example_client

        result = run_example(path,
          MATRIX_HOMESERVER: Async::Matrix::HOMESERVER,
          MATRIX_USER: example_username,
          MATRIX_PASSWORD: Async::Matrix::TEST_PASSWORD,
          CONSOLE_LEVEL: "warn",
        )

        case result
        # Still running when its time was up, which means it reached its sync loop.
        in {status: nil}
          expect(result[:status]).to be_nil

        in {status: Process::Status => status, output: String => output}
          # Ran to the end of its own accord, which the examples taking no room or file do.
          #
          # Anything else is the example and the library no longer agreeing.
          unless status.success?
            raise "#{name} failed:\n\n#{output.lines.last(20).join}"
          end

          expect(status.success?).to be == true
        end
      end
    end
  end
end
