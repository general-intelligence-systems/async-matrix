# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/events"

describe Async::Matrix::Events::Content do
  it "describes no type of its own" do
    expect(subject.event_type).to be_nil
    expect(subject.variant).to be_nil
  end

  it "carries content which arrived without an envelope" do
    content = subject.new({topic: "Planning"})

    expect(content[:topic]).to be == "Planning"
    expect(content.to_h).to be == {topic: "Planning"}
  end

  it "deconstructs to the fields it carries" do
    case subject.new({topic: "Planning"})
    in {topic:}
      expect(topic).to be == "Planning"
    else
      raise "the content did not deconstruct!"
    end
  end

  with "a described type" do
    let(:content) {Async::Matrix::Events::TextMessage.build(body: "hello")}

    it "names the type it belongs to" do
      expect(content.type).to be == "m.room.message"
    end

    # The variant's own field is what distinguishes it, so building one fills it in:
    it "fills in the field which distinguishes the variant" do
      expect(content.to_h).to be == {msgtype: "m.text", body: "hello"}
    end

    it "compares by type and content" do
      expect(content).to be == Async::Matrix::Events::TextMessage.build(body: "hello")
      expect(content).not.to be == Async::Matrix::Events::NoticeMessage.build(body: "hello")
    end
  end
end
