# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/events/undecryptable"

# No homeserver sends these: they are synthesised where a message which cannot be read would have been, so that a sync loop can say why in the same `case` which reads the ones it can.
describe Async::Matrix::Events::Undecryptable do
  let(:value) do
    {
      algorithm: "m.megolm.v1.aes-sha2",
      room_id: "!room:localhost",
      session_id: "session",
      sender_key: "curve",
      reason: "the ratchet would not turn",
    }
  end

  let(:content) {subject.new(value)}

  it "reads what is known about the message it stands for" do
    expect(content.algorithm).to be == "m.megolm.v1.aes-sha2"
    expect(content.room_id).to be == "!room:localhost"
    expect(content.session_id).to be == "session"
    expect(content.sender_key).to be == "curve"
    expect(content.reason).to be == "the ratchet would not turn"
  end

  # It stands where a room event was, so it is framed as one.
  it "is framed as a room event" do
    expect(subject.framing).to be == :room_event
  end

  with "a pattern" do
    it "matches on the fields a caller would report" do
      case content
      in {session_id: String => session_id, reason: String}
        expect(session_id).to be == "session"
      end
    end
  end
end

describe Async::Matrix::Events::Deferred do
  let(:content) {subject.new({session_id: "session"})}

  # The key may still arrive, so this says to wait rather than to give up.
  it "is an undecryptable message which may yet be read" do
    expect(content).to be_a(Async::Matrix::Events::Undecryptable)
    expect(subject.event_type).not.to be == Async::Matrix::Events::Undecryptable.event_type
  end

  it "is told apart from the others by its class" do
    expect(content).not.to be_a(Async::Matrix::Events::Withheld)
  end
end

describe Async::Matrix::Events::Withheld do
  let(:content) {subject.new({session_id: "session", code: "m.unverified", reason: "Verify first."})}

  # Only `m.unverified` ends, so the code is what says whether waiting is pointless.
  it "carries the code the sender refused with" do
    expect(content).to be_a(Async::Matrix::Events::Undecryptable)
    expect(content.code).to be == "m.unverified"
    expect(content.reason).to be == "Verify first."
  end

  it "is matched by its code, which is what a caller acts on" do
    case content
    in {code: "m.unverified"}
      expect(content.code).to be == "m.unverified"
    end
  end
end
