# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/machine"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Machine do
  include Async::Matrix::E2EEContext

  with "#user_id" do
    it "is whoever the access token belongs to" do
      expect(machine.user_id).to be == user_id
      expect(machine.device_id).to be == client.whoami.device_id
    end
  end

  with "#device_keys" do
    it "publishes a key under a name which includes this device" do
      keys = machine.device_keys
      device_id = machine.device_id

      expect(keys[:keys][:"curve25519:#{device_id}"]).to be == crypto.identity_keys[:curve25519]
      expect(keys[:keys][:"ed25519:#{device_id}"]).to be == crypto.identity_keys[:ed25519]
    end

    # Another device trusts these keys only because they are signed by the key they contain.
    it "signs itself, under this device's signing key" do
      keys = machine.device_keys
      signature = keys[:signatures][user_id.to_sym][:"ed25519:#{machine.device_id}"]

      expect(crypto.verify(keys, key: keys[:keys][:"ed25519:#{machine.device_id}"], signature: signature)).to be == true
    end
  end

  with "#publish!" do
    it "uploads a batch of one time keys, and the server says how many it holds" do
      uploaded = machine.publish!

      expect(uploaded.count("signed_curve25519")).to be == crypto.one_time_key_target
      expect(machine.counts[:signed_curve25519]).to be == crypto.one_time_key_target
    end

    # What the server answers with is the whole point of publishing, so it is read rather than counted here.
    it "adds to the keys the server already held" do
      machine.publish!
      uploaded = machine.publish!

      expect(uploaded.count("signed_curve25519")).to be == crypto.one_time_key_target * 2
    end

    it "publishes the device keys, which the server then answers queries with" do
      machine.publish!

      published = client.keys.query({user_id => []}).devices_of(user_id)[machine.device_id.to_sym]

      expect(published[:keys][:"curve25519:#{machine.device_id}"]).to be == crypto.identity_keys[:curve25519]
      expect(published[:algorithms]).to be == crypto.algorithms
    end

    # A key published twice would be claimed twice, and both sessions built on it would be readable by whoever claimed it second.
    it "does not publish the same one time keys again" do
      machine.publish!
      first = client.keys.claim({user_id => {machine.device_id => "signed_curve25519"}})

      machine.publish!
      second = client.keys.claim({user_id => {machine.device_id => "signed_curve25519"}})

      expect(first.one_time_keys[user_id.to_sym]).not.to be == second.one_time_keys[user_id.to_sym]
    end
  end

  with "#top_up!" do
    it "publishes nothing when the server holds enough" do
      machine.publish!
      machine.receive(current_sync)

      expect(machine).not.to be(:one_time_keys_low?)
      expect(machine.top_up!).to be == false
    end

    # A server which has never been given any is as low as a server which has run out.
    it "publishes when the server has never been given any" do
      expect(machine).to be(:one_time_keys_low?)
      expect(machine.top_up!).to be == true
      expect(machine.counts[:signed_curve25519]).to be == crypto.one_time_key_target
    end
  end

  with "#receive" do
    it "reads how many one time keys the server reports holding" do
      machine.publish!

      machine.receive(current_sync)

      expect(machine.counts[:signed_curve25519]).to be == crypto.one_time_key_target
    end

    it "accepts a session which really arrived over to_device" do
      room = shared_room
      other_machine.publish!

      session = machine.share(room.id, [other_user_id])

      receive_device_message(other_machine, other)

      expect(other_store).to be(:session?, room.id, session[:session_id])
      expect(other_store.sessions[[room.id, session[:session_id]]][:sender]).to be == user_id
    end

    it "notes a session which was deliberately withheld" do
      room = shared_room

      client.to_device.send_event("m.room_key.withheld", {other_user_id => {other_device_id => {
        algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
        room_id: room.id,
        session_id: "withheld-session",
        code: "m.unverified",
      }}})

      receive_device_message(other_machine, other)

      expect(other_store.refused(room.id, "withheld-session")).to be == "m.unverified"
      expect(other_store).not.to be(:session?, room.id, "withheld-session")
    end

    # A homeserver sends device events this library has never heard of, and encryption is not the only thing which uses them.
    it "ignores a device message which is not about keys" do
      client.to_device.send_event("com.example.nonsense", {other_user_id => {other_device_id => {hello: "world"}}})

      sync = receive_device_message(other_machine, other)

      expect(sync).not.to be_nil
      expect(other_store.sessions).to be(:empty?)
    end

    it "types each device message the server delivered" do
      room = shared_room
      other_machine.publish!

      session = machine.share(room.id, [other_user_id])

      sync = sync_until(other){|batch| !batch.to_device.empty?}
      typed = other_machine.each_device_event(sync)

      expect(typed.first.content).to be_a(Async::Matrix::Events::RoomKey)
      expect(typed.first.content.session_id).to be == session[:session_id]
      expect(typed.first.content.room_id).to be == room.id
    end
  end

  with "#encrypt" do
    let(:content) {machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "hello"))}

    it "answers content which carries the ciphertext rather than the message" do
      expect(content).to be_a(Async::Matrix::Events::RoomEncrypted)
      expect(content.algorithm).to be == Async::Matrix::E2EE::Machine::MEGOLM
      expect(content.to_h).not.to be(:key?, :body)
    end

    it "says which device encrypted it, and with which session" do
      expect(content.device_id).to be == machine.device_id
      expect(content.sender_key).to be == crypto.identity_keys[:curve25519]
      expect(content.session_id).to be == crypto.session_for(room.id)[:session_id]
    end

    # The homeserver stores it as it is given, which is what makes the room end to end encrypted.
    it "is what the server stores, and nothing of the message" do
      sent = room.send(content)
      stored = room.event(sent.event_id)

      expect(stored.content[:ciphertext]).to be == content.ciphertext
      expect(stored.content).not.to be(:key?, :body)
    end

    # Rotating a session for every message would mean sharing a key for every message.
    it "keeps using the session it already has" do
      first = machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "one"))
      second = machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "two"))

      expect(second.session_id).to be == first.session_id
    end
  end

  with "#decrypt" do
    # The whole flow, through the homeserver: share the key, send the event, and read it as the other user.
    it "reads a message the other user sent into a room" do
      room = shared_room
      machine.publish!

      session = other_machine.share(room.id, [user_id])
      other_room(room).send(other_machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "hello")))

      receive_device_message(machine, client)
      sync = sync_until(client){|batch| batch.each_event.any?{|event| event.type == "m.room.encrypted"}}
      encrypted = sync.each_event.find{|event| event.type == "m.room.encrypted"}

      read = machine.decrypt(encrypted, room_id: room.id)

      expect(read.content).to be_a(Async::Matrix::Events::TextMessage)
      expect(read.content.body).to be == "hello"
      expect(read.sender).to be == other.whoami.user_id
      expect(store).to be(:session?, room.id, session[:session_id])
    end

    # A message this client sent comes back in a sync batch like anybody else's, and a client shows it.
    it "reads back a message of our own" do
      room.send(machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "ours")))

      sync = sync_until(client){|batch| batch.each_event.any?{|event| event.type == "m.room.encrypted"}}
      encrypted = sync.each_event.find{|event| event.type == "m.room.encrypted"}

      expect(machine.decrypt(encrypted, room_id: room.id).content.body).to be == "ours"
    end

    # A client which fell over on an event it cannot read would be stopped by one missing key.
    it "keeps an event whose session has not arrived, rather than failing" do
      room = shared_room
      other_machine.share(room.id, [])
      other_room(room).send(other_machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "hello")))

      sync = sync_until(client){|batch| batch.each_event.any?{|event| event.type == "m.room.encrypted"}}
      encrypted = sync.each_event.find{|event| event.type == "m.room.encrypted"}

      expect(machine.decrypt(encrypted, room_id: room.id)).to be_nil
      expect(store.deferred_count).to be == 1
    end

    it "reads the events which were waiting, once the key arrives" do
      room = shared_room
      session = other_machine.share(room.id, [])
      other_room(room).send(other_machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "late")))

      sync = sync_until(client){|batch| batch.each_event.any?{|event| event.type == "m.room.encrypted"}}
      machine.decrypt(sync.each_event.find{|event| event.type == "m.room.encrypted"}, room_id: room.id)

      machine.publish!
      other_machine.share(room.id, [user_id])
      receive_device_message(machine, client)

      released = machine.release(room.id, session[:session_id])

      expect(released.size).to be == 1
      expect(released.first.content.body).to be == "late"
      expect(store.deferred_count).to be == 0
    end
  end

  with "#share" do
    it "sends the session key to every device the other user has" do
      room = shared_room
      other_machine.publish!

      session = machine.share(room.id, [other_user_id])
      sync = sync_until(other){|batch| !batch.to_device.empty?}
      delivered = sync.to_device.first

      expect(delivered[:type]).to be == "m.room_key"
      expect(delivered[:sender]).to be == user_id
      expect(delivered[:content][:session_id]).to be == session[:session_id]
      expect(delivered[:content][:room_id]).to be == room.id
    end

    # There is nothing to send if nobody else has a device, and an empty request would be refused.
    it "sends nothing when the other user has published no device" do
      room = shared_room

      machine.share(room.id, [other_user_id])

      expect(sync_until(other, attempts: 1, timeout: 200){|batch| !batch.to_device.empty?}).to be_nil
    end

    it "does not send the key to this device" do
      room = shared_room
      machine.publish!

      machine.share(room.id, [user_id])

      expect(sync_until(client, attempts: 1, timeout: 200){|batch| !batch.to_device.empty?}).to be_nil
    end
  end
end
