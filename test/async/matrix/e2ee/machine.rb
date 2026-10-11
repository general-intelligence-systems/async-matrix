# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/machine"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Machine do
  include_context Async::Matrix::E2EEContext

  let(:events) {Async::Matrix::Events.registry(client.version)}

  # What another device sends when it shares a session.
  def room_key(session, sender: "@bob:localhost")
    {
      type: "m.room_key",
      sender: sender,
      content: {
        algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
        room_id: room_id,
        session_id: session[:session_id],
        session_key: session[:session_key],
      },
    }
  end

  with "#user_id" do
    it "is whoever the access token belongs to" do
      expect(machine.user_id).to be == "@alice:localhost"
      expect(machine.device_id).to be == "ALICE"
    end
  end

  with "#device_keys" do
    it "publishes a key under a name which includes this device" do
      keys = machine.device_keys

      expect(keys[:keys][:"curve25519:ALICE"]).to be == crypto.identity_keys[:curve25519]
      expect(keys[:keys][:"ed25519:ALICE"]).to be == crypto.identity_keys[:ed25519]
    end

    it "says who it belongs to and what it can encrypt with" do
      keys = machine.device_keys

      expect(keys[:user_id]).to be == "@alice:localhost"
      expect(keys[:device_id]).to be == "ALICE"
      expect(keys[:algorithms]).to be == crypto.algorithms
    end

    # Another device trusts these keys only because they are signed by the key they contain.
    it "signs itself, under this device's signing key" do
      keys = machine.device_keys
      signature = keys[:signatures][:"@alice:localhost"][:"ed25519:ALICE"]

      expect(signature).not.to be_nil
      expect(crypto.verify(keys, key: keys[:keys][:"ed25519:ALICE"], signature: signature)).to be == true
    end

    # A signature cannot cover itself, so the object which was signed is the one without them.
    it "signs the keys rather than the signatures over them" do
      keys = machine.device_keys

      expect(keys[:signatures][:"@alice:localhost"][:"ed25519:ALICE"]).to be == crypto.sign(keys)
    end
  end

  with "#publish!" do
    it "uploads the device keys and a batch of one time keys" do
      machine.publish!

      upload = homeserver.uploads.last

      expect(upload[:device_keys][:device_id]).to be == "ALICE"
      expect(upload[:one_time_keys].size).to be == Async::Matrix::Offline::TARGET
    end

    it "signs each one time key on its own" do
      machine.publish!

      key = homeserver.uploads.last[:one_time_keys].values.first

      expect(key[:key]).not.to be_nil
      expect(key[:signatures][:"@alice:localhost"][:"ed25519:ALICE"]).to be == crypto.sign({key: key[:key]})
    end

    # A key uploaded twice would be claimed twice, so the keys which were sent are forgotten.
    it "does not upload the same one time keys again" do
      machine.publish!
      first = homeserver.uploads.last[:one_time_keys].keys

      machine.publish!
      second = homeserver.uploads.last[:one_time_keys].keys

      expect(first & second).to be == []
    end

    it "notes how many keys the server now holds" do
      machine.publish!

      expect(machine.counts[:signed_curve25519]).to be == Async::Matrix::Offline::TARGET
    end
  end

  with "#top_up!" do
    it "publishes more when the server is running low" do
      machine.receive(Async::Matrix::Offline::Batch.new(counts: {signed_curve25519: 1}))

      expect(machine).to be(:one_time_keys_low?)
      expect(machine.top_up!).to be == true
      expect(homeserver.uploads.size).to be == 1
    end

    it "publishes nothing when the server holds enough" do
      machine.receive(Async::Matrix::Offline::Batch.new(counts: {signed_curve25519: Async::Matrix::Offline::TARGET}))

      expect(machine).not.to be(:one_time_keys_low?)
      expect(machine.top_up!).to be == false
      expect(homeserver.uploads).to be == []
    end

    # A server which has never been given any is as low as a server which has run out.
    it "publishes when the server has never been given any" do
      expect(machine).to be(:one_time_keys_low?)
    end
  end

  with "#receive" do
    it "notes what the batch said about device lists" do
      machine.receive(Async::Matrix::Offline::Batch.new(changed: ["@bob:localhost"]))

      expect(machine.devices).to be(:stale?, "@bob:localhost")
    end

    it "accepts a session another device shared" do
      session = crypto.create_outbound_session(room_id)

      machine.receive(Async::Matrix::Offline::Batch.new(to_device: [room_key(session)]))

      expect(store).to be(:session?, room_id, session[:session_id])
      expect(store.sessions[[room_id, session[:session_id]]][:sender]).to be == "@bob:localhost"
    end

    it "notes a session which was deliberately withheld" do
      withheld = {
        type: "m.room_key.withheld",
        sender: "@bob:localhost",
        content: {algorithm: Async::Matrix::E2EE::Machine::MEGOLM, room_id: room_id, session_id: "s1", code: "m.unverified"},
      }

      machine.receive(Async::Matrix::Offline::Batch.new(to_device: [withheld]))

      expect(store.refused(room_id, "s1")).to be == "m.unverified"
      expect(store).not.to be(:session?, room_id, "s1")
    end

    # A homeserver sends device events this library has never heard of, and encryption is not the only thing which uses them.
    it "ignores a device event which is not about keys" do
      batch = Async::Matrix::Offline::Batch.new(to_device: [{type: "com.example.nonsense", sender: "@bob:localhost", content: {}}])

      expect(machine.receive(batch)).not.to be_nil
    end

    it "types each device event it was given" do
      session = crypto.create_outbound_session(room_id)

      typed = machine.each_device_event(Async::Matrix::Offline::Batch.new(to_device: [room_key(session)]))

      expect(typed.first.content).to be_a(Async::Matrix::Events::RoomKey)
      expect(typed.first.content.room_id).to be == room_id
    end
  end

  with "#encrypt" do
    it "answers content which carries the ciphertext rather than the event" do
      content = machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: "hello"}))

      expect(content).to be_a(Async::Matrix::Events::RoomEncrypted)
      expect(content.algorithm).to be == Async::Matrix::E2EE::Machine::MEGOLM
      expect(content.ciphertext).not.to be_nil
      expect(content.to_h).not.to be(:key?, :body)
    end

    it "says which device encrypted it, and with which session" do
      content = machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: "hello"}))

      expect(content.device_id).to be == "ALICE"
      expect(content.sender_key).to be == crypto.identity_keys[:curve25519]
      expect(content.session_id).to be == crypto.session_for(room_id)[:session_id]
    end

    it "begins a session for a room it has not encrypted into before" do
      expect(crypto.session_for(room_id)).to be_nil

      machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: "hello"}))

      expect(crypto.session_for(room_id)).not.to be_nil
    end

    # Rotating a session for every message would mean sharing a key for every message.
    it "keeps using the session it already has" do
      first = machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: "one"}))
      second = machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: "two"}))

      expect(second.session_id).to be == first.session_id
    end
  end

  with "#decrypt" do
    # Another device, whose messages arrive with a session this one has never seen.
    let(:bob) {Async::Matrix::E2EE::Plaintext.new}

    def ours(body: "hello")
      content = machine.encrypt(room_id, events.content("m.room.message", {msgtype: "m.text", body: body}))

      events.wrap({type: "m.room.encrypted", event_id: "$1", sender: "@alice:localhost", content: content.to_h})
    end

    def theirs(body: "hello")
      session = bob.create_outbound_session(room_id)
      ciphertext = bob.encrypt(room_id, Async::Matrix::E2EE::CanonicalJSON.dump({type: "m.room.message", room_id: room_id, content: {msgtype: "m.text", body: body}}))

      [session, events.wrap({
        type: "m.room.encrypted",
        event_id: "$1",
        sender: "@bob:localhost",
        content: {
          algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
          sender_key: bob.identity_keys[:curve25519],
          device_id: "BOBPHONE",
          session_id: session[:session_id],
          ciphertext: ciphertext,
        },
      })]
    end

    it "reads the event the ciphertext carried" do
      session, event = theirs
      machine.receive(Async::Matrix::Offline::Batch.new(to_device: [room_key(session)]))

      read = machine.decrypt(event, room_id: room_id)

      expect(read.type).to be == "m.room.message"
      expect(read.content).to be_a(Async::Matrix::Events::TextMessage)
      expect(read.content.body).to be == "hello"
    end

    # A message this client sent comes back in a sync batch like anybody else's, and a client shows it.
    it "reads back a message of our own" do
      read = machine.decrypt(ours(body: "ours"), room_id: room_id)

      expect(read.content.body).to be == "ours"
    end

    # A client which fell over on an event it cannot read would be stopped by one missing key.
    it "keeps an event whose session has not arrived, rather than failing" do
      _, event = theirs

      expect(machine.decrypt(event, room_id: room_id)).to be_nil
      expect(store.deferred_count).to be == 1
    end

    it "reads the events which were waiting, once the session arrives" do
      session, event = theirs

      machine.decrypt(event, room_id: room_id)
      machine.receive(Async::Matrix::Offline::Batch.new(to_device: [room_key(session)]))

      released = machine.release(room_id, session[:session_id])

      expect(released.size).to be == 1
      expect(released.first.content.body).to be == "hello"
      expect(store.deferred_count).to be == 0
    end

    it "frames what it read as an event of the room it arrived in" do
      session, event = theirs
      machine.receive(Async::Matrix::Offline::Batch.new(to_device: [room_key(session)]))

      read = machine.decrypt(event, room_id: room_id)

      expect(read).to be_a(Async::Matrix::Events::RoomEvent)
      expect(read.room_id).to be == room_id
      expect(read.sender).to be == "@bob:localhost"
    end

    it "has nothing to release for a session nothing waited on" do
      expect(machine.release(room_id, "never")).to be == []
    end
  end

  with "#share" do
    it "sends the session key to every device of the users it was given" do
      homeserver.device("@bob:localhost", "BOBPHONE", {algorithms: [Async::Matrix::E2EE::Machine::MEGOLM], keys: {}})

      session = machine.share(room_id, ["@bob:localhost"])
      type, messages = homeserver.sent.last

      expect(type).to be == "m.room_key"
      expect(messages["@bob:localhost"]["BOBPHONE"][:session_id]).to be == session[:session_id]
      expect(messages["@bob:localhost"]["BOBPHONE"][:room_id]).to be == room_id
    end

    # There is nothing to send if nobody else is in the room, and an empty request would be refused.
    it "sends nothing when there is nobody to send to" do
      machine.share(room_id, ["@bob:localhost"])

      expect(homeserver.sent).to be == []
    end

    it "does not send the key to this device" do
      homeserver.device("@alice:localhost", "ALICE", {algorithms: [Async::Matrix::E2EE::Machine::MEGOLM], keys: {}})

      machine.share(room_id, ["@alice:localhost"])

      expect(homeserver.sent).to be == []
    end
  end
end
