# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/events"

describe Async::Matrix::Events::Readers do
  let(:klass) do
    Class.new(Async::Matrix::Events::Content) do
      extend Async::Matrix::Events::Readers

      reads "m.relates_to"
    end
  end

  let(:content) {klass.new({:"m.relates_to" => {event_id: "$1"}})}

  it "reads the field under the name the specification gives it" do
    expect(content.send("m.relates_to")).to be == {event_id: "$1"}
  end

  it "reads it under a name which is callable without send" do
    expect(content.m_relates_to).to be == {event_id: "$1"}
  end

  it "reads it under the name without the prefix every type carries" do
    expect(content.relates_to).to be == {event_id: "$1"}
  end

  with "a name which is already read" do
    let(:klass) do
      Class.new(Async::Matrix::Events::Content) do
        extend Async::Matrix::Events::Readers

        def topic = @value[:topic]

        reads "m.topic"
      end
    end

    let(:content) {klass.new({topic: "plain", :"m.topic" => {:"m.text" => []}})}

    # `m.room.topic` carries both, so the shorter name cannot be taken by the longer field.
    it "leaves the existing reader alone" do
      expect(content.topic).to be == "plain"
      expect(content.m_topic).to be == {:"m.text" => []}
      expect(content.send("m.topic")).to be == {:"m.text" => []}
    end
  end
end
