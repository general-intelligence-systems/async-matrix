# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/event_id"

describe Async::Matrix::Identifier::EventID do
  with ".parse" do
    # Room versions 1 and 2 wrote the server into the event ID.
    it "reads an event ID which names a server" do
      event = subject.parse("$h29iv0s8:example.com")

      expect(event.localpart).to be == "h29iv0s8"
      expect(event.server_name.to_s).to be == "example.com"
      expect(event.namespaced?).to be == true
    end

    # Room version 3 uses the reference hash as unpadded base64, which has no colon in it.
    it "reads an event ID which is a hash" do
      event = subject.parse("$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk")

      expect(event.server_name).to be_nil
      expect(event.namespaced?).to be == false
    end

    # Room versions 4 and 5 onwards write the same hash URL-safe.
    it "reads an event ID whose hash is URL-safe" do
      expect(subject.parse("$Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg").namespaced?).to be == false
    end

    it "refuses another kind's sigil" do
      expect{subject.parse("!abc:example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end

    it "refuses an event ID longer than the limit" do
      expect{subject.parse("$#{"a" * 255}")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#to_s" do
    it "writes back what it read" do
      ["$h29iv0s8:example.com", "$acR1l0raoZnm60CBwAVgqbZqoO/mYU81xysh1u7XcJk"].each do |string|
        expect(subject.parse(string).to_s).to be == string
      end
    end
  end
end
