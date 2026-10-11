# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/events"
require "async/matrix/events_context"

require_relative "../abstract/events/room_message"

describe Async::Matrix::Events::Message do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext

  it "names the type and the framing the specification gives it" do
    expect(subject.event_type).to be == "m.room.message"
    expect(subject.framing).to be == :room_event
  end

  it "reads what every message has" do
    message = subject.new({msgtype: "m.beeps", body: "hello"})

    expect(message.body).to be == "hello"
    expect(message.msgtype).to be == "m.beeps"
  end

  with "the variants" do
    it "each name their own msgtype" do
      expect(Async::Matrix::Events::TextMessage.variant).to be == {msgtype: "m.text"}
      expect(Async::Matrix::Events::EmoteMessage.variant).to be == {msgtype: "m.emote"}
      expect(Async::Matrix::Events::NoticeMessage.variant).to be == {msgtype: "m.notice"}
      expect(Async::Matrix::Events::FileMessage.variant).to be == {msgtype: "m.file"}
      expect(Async::Matrix::Events::ImageMessage.variant).to be == {msgtype: "m.image"}
      expect(Async::Matrix::Events::AudioMessage.variant).to be == {msgtype: "m.audio"}
      expect(Async::Matrix::Events::VideoMessage.variant).to be == {msgtype: "m.video"}
      expect(Async::Matrix::Events::LocationMessage.variant).to be == {msgtype: "m.location"}
      expect(Async::Matrix::Events::ServerNoticeMessage.variant).to be == {msgtype: "m.server_notice"}
      expect(Async::Matrix::Events::KeyVerificationRequestMessage.variant).to be == {msgtype: "m.key.verification.request"}
    end

    it "all describe the same type" do
      [Async::Matrix::Events::TextMessage, Async::Matrix::Events::ImageMessage].each do |klass|
        expect(klass.event_type).to be == "m.room.message"
      end
    end
  end

  with "an upload" do
    let(:image) do
      Async::Matrix::Events::ImageMessage.new({
        msgtype: "m.image",
        body: "cat.png",
        url: "mxc://localhost/1",
        info: {w: 64, h: 64, mimetype: "image/png"},
      })
    end

    it "reads how the file is reached" do
      expect(image.url).to be == "mxc://localhost/1"
      expect(image.info[:mimetype]).to be == "image/png"
    end

    it "deconstructs so that a pattern can read into the info" do
      case image
      in {body:, info: {mimetype:}}
        expect(body).to be == "cat.png"
        expect(mimetype).to be == "image/png"
      else
        raise "the image did not deconstruct!"
      end
    end
  end

  with "a key verification request" do
    let(:request) do
      Async::Matrix::Events::KeyVerificationRequestMessage.new({
        msgtype: "m.key.verification.request",
        from_device: "ABC",
        methods: ["m.sas.v1"],
        to: "@bob:localhost",
      })
    end

    # Reading the `methods` field through a method of that name would override `Object#methods`.
    it "reads the methods it offers without shadowing introspection" do
      expect(request.verification_methods).to be == ["m.sas.v1"]
      expect(request.methods).to be_a(Array)
      expect(request.methods).to be(:include?, :verification_methods)
    end
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Events::Message::CASES
end
