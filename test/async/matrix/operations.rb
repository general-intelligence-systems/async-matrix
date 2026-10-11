# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations"

describe Async::Matrix::Operations do
  it "underscores a camelCase operation" do
    expect(Async::Matrix::Operations.method_name("getRoomEvents")).to be == :get_room_events
  end

  it "separates a digit from the word before it" do
    expect(Async::Matrix::Operations.method_name("add3PID")).to be == :add_3pid
  end

  it "keeps a plural acronym as one word" do
    expect(Async::Matrix::Operations.method_name("get3PIDs")).to be == :get_3pids
  end

  it "separates an acronym from the word after it" do
    expect(Async::Matrix::Operations.method_name("requestTokenTo3PIDEmail")).to be == :request_token_to_3pid_email
  end

  # The identifier does not say where one word ends, so the rule cannot be asked to.
  it "names the irregular operations outright" do
    expect(Async::Matrix::Operations.method_name("redirectToIdP")).to be == :redirect_to_idp
    expect(Async::Matrix::Operations.method_name("requestTokenTo3PIDMSISDN")).to be == :request_token_to_3pid_msisdn
  end

  it "leaves an operation which is already one word alone" do
    expect(Async::Matrix::Operations.method_name("refresh")).to be == :refresh
  end
end
