# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/store"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Store do
  include Async::Matrix::E2EEContext

  # A room both users are in, and the other user's keys published, which is what sharing a session needs.
  def prepared
    shared_room.tap do
      other_machine.publish!
    end
  end

  # The encrypted event the other user sent into the room, as it came back from sync.
  def encrypted_in(room)
    room.send(other_machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "hello")))

    sync = sync_until(client){|batch| batch.each_event.any?{|event| event.type == "m.room.encrypted"}}

    sync.each_event.find{|event| event.type == "m.room.encrypted"}
  end

  with "#remember" do
    it "holds a session which really arrived over to_device" do
      room = prepared
      session = other_machine.share(room.id, [user_id])

      receive_device_message(machine, client)

      expect(store).to be(:session?, room.id, session[:session_id])
      expect(store.sessions[[room.id, session[:session_id]]][:sender]).to be == other_user_id
    end

    # A session ID is unique to the device which made it, not to the room, so both are needed to tell one from another.
    it "does not hold that session for another room" do
      room = prepared
      session = other_machine.share(room.id, [user_id])

      receive_device_message(machine, client)

      expect(store).not.to be(:session?, client.create_room.id, session[:session_id])
    end

    it "holds nothing before anything has been shared" do
      machine.receive(current_sync)

      expect(store.sessions).to be(:empty?)
    end
  end

  with "#refuse" do
    # A sender which deliberately withholds a key says why, and that is worth showing rather than reporting the event as broken.
    it "notes why a session was refused" do
      room = prepared

      other.to_device.send_event("m.room_key.withheld", {user_id => {client.whoami.device_id => {
        algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
        room_id: room.id,
        session_id: "refused-session",
        code: "m.unverified",
      }}})

      receive_device_message(machine, client)

      expect(store.refused(room.id, "refused-session")).to be == "m.unverified"
      expect(store).not.to be(:session?, room.id, "refused-session")
    end

    it "answers nothing for a session which was not refused" do
      expect(store.refused(room.id, "never")).to be_nil
    end
  end

  with "#defer" do
    # A key can arrive after the events it unlocks, so an event which cannot be read is kept rather than lost.
    it "keeps an event whose key has not arrived" do
      room = prepared
      other_machine.share(room.id, [])

      machine.decrypt(encrypted_in(room), room_id: room.id)

      expect(store.deferred_count).to be == 1
    end

    it "releases it once, because it is read when the key arrives" do
      room = prepared
      session = other_machine.share(room.id, [])

      machine.decrypt(encrypted_in(room), room_id: room.id)

      expect(store.deferred(room.id, session[:session_id]).size).to be == 1
      expect(store.deferred(room.id, session[:session_id])).to be == []
      expect(store.deferred_count).to be == 0
    end

    it "answers nothing for a session nothing waited on" do
      expect(store.deferred(room.id, "never")).to be == []
    end
  end
end
