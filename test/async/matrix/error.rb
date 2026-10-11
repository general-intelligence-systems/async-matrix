# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/error"

describe Async::Matrix::RequestError do
  let(:error) {subject.new(403, "M_FORBIDDEN", "You are not allowed.")}

  it "carries the status and the error code" do
    expect(error.status).to be == 403
    expect(error.errcode).to be == "M_FORBIDDEN"
  end

  it "reads as the code and the message" do
    expect(error.to_s).to be == "M_FORBIDDEN: You are not allowed."
  end

  # The message falls back to the code, and the code is what it reads as, so both appear.
  it "falls back to the code when there is no message" do
    expect(subject.new(403, "M_FORBIDDEN").message).to be == "M_FORBIDDEN: M_FORBIDDEN"
  end

  it "falls back to the status when there is neither" do
    expect(subject.new(500, nil).message).to be == "500: HTTP 500"
  end

  with "#unknown_token?" do
    it "is true for a missing or unknown token" do
      expect(subject.new(401, "M_UNKNOWN_TOKEN")).to be(:unknown_token?)
      expect(subject.new(401, "M_MISSING_TOKEN")).to be(:unknown_token?)
      expect(subject.new(403, "M_FORBIDDEN")).not.to be(:unknown_token?)
    end
  end

  with "#limit_exceeded?" do
    it "is true for a rate limit" do
      expect(subject.new(429, "M_LIMIT_EXCEEDED")).to be(:limit_exceeded?)
      expect(subject.new(403, "M_FORBIDDEN")).not.to be(:limit_exceeded?)
    end
  end

  it "is an error this library raised" do
    expect(error).to be_a(Async::Matrix::Error)
    expect(error).to be_a(StandardError)
  end
end

describe Async::Matrix::InteractiveAuthenticationError do
  let(:challenge) do
    subject.new(401, nil, nil,
      session: "a-session",
      flows: [{stages: ["m.login.password"]}, {stages: ["m.login.sso", "m.login.password"]}],
      params: {"m.login.terms" => {policies: {}}},
      completed: [],
    )
  end

  it "is a request error, so a caller which handles one handles this" do
    expect(challenge).to be_a(Async::Matrix::RequestError)
  end

  it "reports the session to carry through the stages" do
    expect(challenge.session).to be == "a-session"
  end

  it "reports the stages of each flow" do
    expect(challenge.stages).to be == [["m.login.password"], ["m.login.sso", "m.login.password"]]
  end

  it "accepts a single stage which completes a flow" do
    expect(challenge).to be(:accepts?, "m.login.password")
  end

  it "does not accept a stage which leaves a flow unfinished" do
    expect(challenge).not.to be(:accepts?, "m.login.sso")
  end

  it "accepts a stage once the others are completed" do
    partial = subject.new(401, nil, nil, session: "a-session", flows: [{stages: ["m.login.sso", "m.login.password"]}], completed: ["m.login.sso"])

    expect(partial).to be(:accepts?, "m.login.password")
  end

  it "reports the parameters a stage needs" do
    expect(challenge.params).to be(:key?, "m.login.terms")
  end

  it "says what it wants when the homeserver did not" do
    expect(challenge.message).to be(:include?, "requires authentication")
  end
end
