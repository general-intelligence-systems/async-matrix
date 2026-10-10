# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/events"

require_relative "abstract/events/room_message"

describe Async::Matrix::Events do
  with ".[]" do
    it "builds the events for a version" do
      expect(subject["v1.19"]::SPEC_VERSION).to be == "v1.19"
      expect(subject["v1.19"]::TextMessage).to be < Async::Matrix::Events::TextMessage
    end

    it "applies the layers up to that version" do
      expect(subject["v1.10"]::ImageMessage.instance_methods).to be(:include?, :filename)
      expect(subject["v1.9"]::ImageMessage.instance_methods).not.to be(:include?, :filename)
    end

    # `m.file` named its upload before the other media messages did, so the version which added
    # the caption fields did not add a filename to it.
    it "leaves a type alone where the version changed something else" do
      expect(subject["v1.9"]::FileMessage.instance_methods).to be(:include?, :filename)
      expect(subject["v1.9"]::FileMessage.instance_methods).not.to be(:include?, :format)
      expect(subject["v1.10"]::FileMessage.instance_methods).to be(:include?, :format)
    end
  end

  with ".registry" do
    it "answers the unversioned classes when no version is given" do
      expect(subject.registry.content_class("m.room.message", {msgtype: "m.text"})).to be_equal(Async::Matrix::Events::TextMessage)
    end

    it "answers the versioned classes for a version" do
      expect(subject.registry("v1.19").content_class("m.room.message", {msgtype: "m.text"})).to be_equal(subject["v1.19"]::TextMessage)
    end
  end
end
