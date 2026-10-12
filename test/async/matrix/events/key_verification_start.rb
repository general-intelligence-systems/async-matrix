# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/events_context"

describe Async::Matrix::Events::KeyVerificationStart do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext
end

describe Async::Matrix::Events::KeyVerificationStartSasV1 do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext

  # What the other device said it understands, which is everything the specification defines.
  let(:both) do
    subject.new(
      method: "m.sas.v1",
      from_device: "THEIRS",
      transaction_id: "txn",
      short_authentication_string: ["decimal", "emoji"],
    )
  end

  with "::OFFERED" do
    # MSC4405: the emoji names are translated per client, so two users can hold different words for one picture.
    it "offers decimal alone, because emoji is deprecated" do
      expect(subject::OFFERED).to be == ["decimal"]
    end

    # Decimal is required of every client, so offering only decimal still agrees with anybody.
    it "offers a method every client must understand" do
      expect(subject::DEFINED).to be(:include?, "decimal")
      expect(subject::OFFERED - subject::DEFINED).to be(:empty?)
    end
  end

  with "#agreed" do
    # The accept must name a subset of what the start offered, so this is what goes into it.
    it "narrows what the other device offered to what we will use" do
      expect(both.agreed).to be == ["decimal"]
    end

    it "agrees with a device which offers decimal alone" do
      start = subject.new(method: "m.sas.v1", short_authentication_string: ["decimal"])

      expect(start.agreed).to be == ["decimal"]
    end

    # A device which somehow offers no decimal is one we cannot verify with, and saying so is the caller's cue to cancel.
    it "agrees on nothing with a device which offers emoji alone" do
      start = subject.new(method: "m.sas.v1", short_authentication_string: ["emoji"])

      expect(start.agreed).to be(:empty?)
    end

    it "agrees on nothing with a device which offered no methods at all" do
      start = subject.new(method: "m.sas.v1")

      expect(start.agreed).to be(:empty?)
    end

    # A client which has reason to show emoji may still ask for it, so the policy is a default rather than a rule.
    it "can be asked for a method which is not offered by default" do
      expect(both.agreed(offered: ["emoji"])).to be == ["emoji"]
      expect(both.agreed(offered: ["decimal", "emoji"])).to be == ["decimal", "emoji"]
    end
  end

  # The registry picks this class by the method, which is what lets a pattern match on it.
  with "the registry" do
    it "reads an m.sas.v1 start as this class" do
      content = Async::Matrix::Events.registry(Async::Matrix::LATEST).content(
        "m.key.verification.start",
        {method: "m.sas.v1", short_authentication_string: ["decimal"]},
      )

      expect(content).to be_a(subject)
      expect(content.agreed).to be == ["decimal"]
    end
  end
end
