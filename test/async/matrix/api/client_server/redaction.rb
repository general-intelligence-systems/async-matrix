# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Redaction do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:sent) {room.send_message("m.room.message", {msgtype: "m.text", body: "something regrettable"})}

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can redactEvent" do
    expect(client.redaction.redact_event(room.id, sent.event_id, reason: "thought better of it").event_id).to be_a(String)
  end

  # The redaction is an event of its own, so it has an ID the sent event does not.
  it "answers with the redaction rather than the event redacted" do
    redaction = client.redaction.redact_event(room.id, sent.event_id)

    expect(redaction.event_id).not.to be == sent.event_id
  end

  # The content goes; the event itself stays, with its type and its sender.
  it "strips the content of the event" do
    client.redaction.redact_event(room.id, sent.event_id)

    expect(room.get_one_room_event(sent.event_id).content).to be(:empty?)
  end
end
