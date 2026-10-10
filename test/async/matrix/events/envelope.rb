# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/events"

describe Async::Matrix::Events::Envelope do
  let(:content) {Async::Matrix::Events::TextMessage.new({msgtype: "m.text", body: "hello"})}

  with "a room event" do
    let(:value) do
      {
        type: "m.room.message",
        event_id: "$1",
        sender: "@alice:localhost",
        origin_server_ts: 1,
        content: {msgtype: "m.text", body: "hello"},
      }
    end

    let(:event) {Async::Matrix::Events::RoomEvent.new(value, content, room_id: "!room:localhost")}

    it "reads the fields a timeline entry has" do
      expect(event.type).to be == "m.room.message"
      expect(event.event_id).to be == "$1"
      expect(event.sender).to be == "@alice:localhost"
      expect(event.origin_server_ts).to be == 1
    end

    # `/sync` groups events by room instead of naming it on each one.
    it "takes the room from the caller when the event does not name it" do
      expect(event.room_id).to be == "!room:localhost"
    end

    it "prefers the room the event names" do
      event = Async::Matrix::Events::RoomEvent.new(value.merge(room_id: "!named:localhost"), content, room_id: "!room:localhost")

      expect(event.room_id).to be == "!named:localhost"
    end

    it "deconstructs to its own fields and the content" do
      case event
      in {sender:, room_id:, content: Async::Matrix::Events::TextMessage(body:)}
        expect(sender).to be == "@alice:localhost"
        expect(room_id).to be == "!room:localhost"
        expect(body).to be == "hello"
      else
        raise "the envelope did not deconstruct!"
      end
    end

    # Six event types declare content fields which collide with envelope names, so the two are
    # never merged into one namespace.
    it "does not merge the content into its own fields" do
      expect(event.deconstruct_keys(nil).keys).not.to be(:include?, :body)
      expect(event.deconstruct_keys(nil)[:content]).to be_equal(content)
    end

    it "gives the raw event for anything it does not name" do
      expect(event[:type]).to be == "m.room.message"
      expect(event.dig(:content, :body)).to be == "hello"
      expect(event.to_h).to be == value
    end
  end

  with "a state event" do
    let(:value) {{type: "m.room.topic", state_key: "", content: {topic: "Planning"}}}
    let(:event) {Async::Matrix::Events::StateEvent.new(value, content)}

    it "reads the state key" do
      expect(event.state_key).to be == ""
    end

    it "deconstructs with the state key" do
      case event
      in {state_key: ""}
        nil
      else
        raise "the state event did not deconstruct!"
      end
    end
  end
end
