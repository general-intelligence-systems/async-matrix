# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/events"

describe Async::Matrix::Events::Registry do
  let(:registry) {Async::Matrix::Events.registry}

  with "#content_class" do
    it "dispatches on the type, and then on the field which distinguishes a variant" do
      expect(registry.content_class("m.room.message", {msgtype: "m.text"})).to be_equal(Async::Matrix::Events::TextMessage)
      expect(registry.content_class("m.room.message", {msgtype: "m.image"})).to be_equal(Async::Matrix::Events::ImageMessage)
    end

    # The specification declares a bare `m.room.message` alongside its variants, which is what an unrecognised `msgtype` is read as: the body is still there to be shown.
    it "falls back to the type itself for an unknown variant" do
      expect(registry.content_class("m.room.message", {msgtype: "m.beeps"})).to be_equal(Async::Matrix::Events::Message)
    end

    it "falls back to content for an unknown type" do
      expect(registry.content_class("com.example.nonsense", {})).to be_equal(Async::Matrix::Events::Content)
    end
  end

  with "#wrap" do
    it "frames a message as a timeline entry" do
      event = registry.wrap({type: "m.room.message", event_id: "$1", content: {msgtype: "m.text", body: "hi"}}, room_id: "!r:localhost")

      expect(event).to be_a(Async::Matrix::Events::RoomEvent)
      expect(event.content).to be_a(Async::Matrix::Events::TextMessage)
      expect(event.content.body).to be == "hi"
      expect(event.room_id).to be == "!r:localhost"
    end

    # A homeserver will send types this library has never heard of, so the framing is taken from what the event itself carries.
    it "frames an unknown type by what it carries" do
      state = registry.wrap({type: "com.example.thing", state_key: "", content: {}})
      timeline = registry.wrap({type: "com.example.thing", event_id: "$1", content: {}})
      bare = registry.wrap({type: "com.example.thing", content: {}})

      expect(state).to be_a(Async::Matrix::Events::StateEvent)
      expect(timeline).to be_a(Async::Matrix::Events::RoomEvent)
      expect(bare).to be_a(Async::Matrix::Events::Envelope)
      expect(bare).not.to be_a(Async::Matrix::Events::RoomEvent)
    end

    it "tolerates an event with no content at all" do
      event = registry.wrap({type: "m.room.message"})

      expect(event.content).to be_a(Async::Matrix::Events::Message)
      expect(event.content.body).to be_nil
    end
  end

  with "#content" do
    # `GET /rooms/{roomId}/state/{eventType}/{stateKey}` answers with the content alone.
    it "types content which arrived without an envelope" do
      content = registry.content("m.room.message", {msgtype: "m.notice", body: "hi"})

      expect(content).to be_a(Async::Matrix::Events::NoticeMessage)
      expect(content.body).to be == "hi"
    end
  end

  with "a version" do
    it "is built from the classes of that version" do
      expect(Async::Matrix::Events.registry("v1.19")).not.to be_equal(Async::Matrix::Events.registry("v1.9"))
    end

    it "is cached" do
      expect(Async::Matrix::Events.registry("v1.19")).to be_equal(Async::Matrix::Events.registry("v1.19"))
    end
  end
end
