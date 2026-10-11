# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/event_context"

describe Async::Matrix::ClientServer::EventContext do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:first) {room.send_message("m.room.message", {msgtype: "m.text", body: "the one before"})}

  let(:middle) {room.send_message("m.room.message", {msgtype: "m.text", body: "the one asked about"})}

  let(:last) {room.send_message("m.room.message", {msgtype: "m.text", body: "the one after"})}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can getEventContext" do
    first
    asked = middle
    last

    context = client.event_context.get_event_context(room.id, asked.event_id, limit: 5)

    expect(context.event[:event_id]).to be == asked.event_id
  end

  it "answers with the events either side of it" do
    before = first
    asked = middle
    after = last

    context = client.event_context.get_event_context(room.id, asked.event_id, limit: 5)

    expect(context.events_before.map{|event| event[:event_id]}).to be(:include?, before.event_id)
    expect(context.events_after.map{|event| event[:event_id]}).to be(:include?, after.event_id)
  end

  it "answers with the state of the room and the tokens to page from" do
    context = client.event_context.get_event_context(room.id, middle.event_id)

    expect(context.state).not.to be(:empty?)
    expect(context.start).to be_a(String)
    expect(context.finish).to be_a(String)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::EventContext::CASES
end
