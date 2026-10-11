# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/plaintext"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Plaintext do
  include Async::Matrix::E2EEContext

  with "#identity_keys" do
    it "answers a long lived key for each algorithm it signs and encrypts with" do
      expect(crypto.identity_keys.keys).to be == [:curve25519, :ed25519]
      expect(crypto.identity_keys[:curve25519]).not.to be == crypto.identity_keys[:ed25519]
    end

    # They are this device's identity, so they are the keys the homeserver answers with ever after.
    it "answers the same keys the homeserver was given" do
      machine.publish!

      published = client.keys.query_keys({user_id => []}).devices_of(user_id)[machine.device_id.to_sym]

      expect(published[:keys][:"ed25519:#{machine.device_id}"]).to be == crypto.identity_keys[:ed25519]
      expect(crypto.identity_keys).to be == crypto.identity_keys
    end
  end

  with "#sign" do
    it "signs the canonical form, so that the order keys were given in does not matter" do
      expect(crypto.sign({a: 1, b: 2})).to be == crypto.sign({b: 2, a: 1})
      expect(crypto.sign({a: 1})).not.to be == crypto.sign({a: 2})
    end

    it "verifies what it signed, and nothing else" do
      expect(crypto.verify({a: 1}, key: crypto.identity_keys[:ed25519], signature: crypto.sign({a: 1}))).to be == true
      expect(crypto.verify({a: 1}, key: crypto.identity_keys[:ed25519], signature: crypto.sign({a: 2}))).to be == false
    end

    # Nothing here is a signature, and a caller which mistook one for a signature should be able to tell.
    it "says in the signature that it is not one" do
      expect(crypto.sign({a: 1})).to be(:start_with?, "#{subject::MARKER}:")
    end
  end

  with "#one_time_keys" do
    it "generates the number asked for, and keys them as a server claims them" do
      expect(crypto.generate_one_time_keys(3).size).to be == 3
      expect(crypto.one_time_keys.size).to be == 3
      expect(crypto.one_time_keys.keys.first.to_s).to be(:start_with?, "signed_curve25519:")
    end

    it "accumulates keys which have not been published" do
      crypto.generate_one_time_keys(2)
      crypto.generate_one_time_keys(2)

      expect(crypto.one_time_keys.size).to be == 4
    end

    # A homeserver hands out one of these to each device which wants a session, so what it gives out must be what was made.
    it "generates keys a homeserver will hold and hand back" do
      crypto.generate_one_time_keys(1)
      made = crypto.one_time_keys.values.first

      client.keys.upload_keys(device_keys: machine.device_keys, one_time_keys: machine.signed_one_time_keys)
      claimed = client.keys.claim_keys({user_id => {machine.device_id => "signed_curve25519"}})

      expect(claimed.one_time_keys[user_id.to_sym][machine.device_id.to_sym].values.first[:key]).to be == made
    end

    # A key published twice would be claimed twice, and a session built on it would be read by whoever claimed it second.
    it "forgets the keys which were published" do
      crypto.generate_one_time_keys(2)
      crypto.published_one_time_keys!

      expect(crypto.one_time_keys).to be(:empty?)
    end

    it "answers a target for a server to hold" do
      expect(subject.new(one_time_key_target: 10).one_time_key_target).to be == 10
    end
  end

  with "#create_outbound_session" do
    it "answers a session and the key which shares it" do
      session = crypto.create_outbound_session(room.id)

      expect(session[:session_id]).not.to be_nil
      expect(crypto.session_for(room.id)).to be == session
    end

    it "has no session for a room it has not begun one for" do
      crypto.create_outbound_session(room.id)

      expect(crypto.session_for("!other:localhost")).to be_nil
    end

    it "begins a distinct session for each room" do
      first = crypto.create_outbound_session(room.id)
      second = crypto.create_outbound_session(client.create_room.id)

      expect(first[:session_id]).not.to be == second[:session_id]
    end
  end

  with "#decrypt" do
    # The point of this implementation: the whole flow can be driven, because what it writes can be read back.
    it "reads back what another device wrote, once its session has been accepted" do
      session = other_crypto.create_outbound_session(room.id)
      ciphertext = other_crypto.encrypt(room.id, %({"a":1}))

      crypto.create_inbound_session(room.id, session_id: session[:session_id], session_key: session[:session_key])

      expect(crypto.decrypt(room.id, session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    it "refuses a session it was never given" do
      crypto.create_outbound_session(room.id)
      ciphertext = crypto.encrypt(room.id, %({"a":1}))

      expect{crypto.decrypt(room.id, session_id: "never", ciphertext: ciphertext)}.to raise_exception(KeyError)
    end

    # Encrypting into a room with no session would write a message nobody holds the key for, including us.
    it "refuses to encrypt for a room it has begun no session for" do
      expect{crypto.encrypt(room.id, %({"a":1}))}.to raise_exception(KeyError)
    end

    # A client shows the messages it sent, which come back in a sync batch like anybody else's.
    it "reads its own messages, without being given its own session" do
      session = crypto.create_outbound_session(room.id)
      ciphertext = crypto.encrypt(room.id, %({"a":1}))

      expect(crypto.decrypt(room.id, session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    it "refuses something another implementation wrote" do
      session = crypto.create_outbound_session(room.id)

      expect{crypto.decrypt(room.id, session_id: session[:session_id], ciphertext: "AwgAEnB0:xyz")}.to raise_exception(ArgumentError)
    end

    # What the homeserver stored is what is read, so nothing in between may alter it.
    it "reads what the homeserver stored, rather than what was encrypted" do
      content = machine.encrypt(room.id, Async::Matrix::Events::TextMessage.build(body: "stored"))
      sent = room.send_message(content.type, content.to_h)
      stored = room.get_one_room_event(sent.event_id)

      plaintext, _ = crypto.decrypt(room.id, session_id: content.session_id, ciphertext: stored.content[:ciphertext])

      expect(JSON.parse(plaintext, symbolize_names: true)[:content][:body]).to be == "stored"
    end
  end

  with "#algorithms" do
    # A device which did not offer Olm could never be sent a room key, because that is what carries one.
    it "offers both ratchets, because the room keys travel over Olm" do
      expect(crypto.algorithms).to be == [subject::OLM, subject::MEGOLM]
    end
  end

  with "#generate_fallback_key" do
    it "generates a key the server may hand out more than once" do
      expect(crypto.fallback_key).to be(:empty?)

      crypto.generate_fallback_key

      expect(crypto.fallback_key.size).to be == 1
      expect(crypto.fallback_key.keys.first.to_s).to be(:start_with?, "signed_curve25519:")
    end
  end

  with "#encrypt_to_device" do
    let(:their_key) {other_crypto.identity_keys[:curve25519]}

    it "has no session with a device it has not claimed a key for" do
      expect(crypto.session?(their_key)).to be == false
      expect{crypto.encrypt_to_device(their_key, %({"a":1}))}.to raise_exception(KeyError)
    end

    # This is what carries every key: a room key is an Olm message before it is anything else.
    it "writes a pre-key message, which the other device adopts as a session" do
      other_crypto.generate_one_time_keys(1)
      crypto.open_session(identity_key: their_key, one_time_key: other_crypto.one_time_keys.values.first)

      type, body = crypto.encrypt_to_device(their_key, %({"type":"m.room_key"}))
      read = other_crypto.accept_session(identity_key: crypto.identity_keys[:curve25519], body: body)

      expect(type).to be == 0
      expect(read).to be == %({"type":"m.room_key"})
    end

    # Olm sends pre-key messages until one arrives over the session, which is how the other side knows to keep it.
    it "writes a normal message once one has arrived over the session" do
      other_crypto.generate_one_time_keys(1)
      crypto.open_session(identity_key: their_key, one_time_key: other_crypto.one_time_keys.values.first)

      _, body = crypto.encrypt_to_device(their_key, %({"a":1}))
      crypto.decrypt_from_device(their_key, type: 0, body: body)

      type, _ = crypto.encrypt_to_device(their_key, %({"b":2}))

      expect(type).to be == 1
    end
  end

  with "#export_session" do
    it "exports a session another device can import" do
      session = crypto.create_outbound_session(room.id)
      ciphertext = crypto.encrypt(room.id, %({"a":1}))
      exported = crypto.export_session(session[:session_id], index: 0)

      other_crypto.import_inbound_session(room.id, session_id: session[:session_id], exported_key: exported)

      expect(other_crypto.decrypt(room.id, session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    # Megolm ratchets forward only, so a key for an earlier message cannot be produced from a later one.
    it "cannot export a session from before where it begins" do
      session = crypto.create_outbound_session(room.id)
      exported = crypto.export_session(session[:session_id], index: 0)

      other_crypto.import_inbound_session(room.id, session_id: session[:session_id], exported_key: exported, index: 4)

      expect(other_crypto.export_session(session[:session_id], index: 0)).to be_nil
    end
  end

  with "#dump" do
    # A device which forgot its sessions on restart would lose every message it had already been sent the key for.
    it "restores everything it was dumped with" do
      session = crypto.create_outbound_session(room.id)
      ciphertext = crypto.encrypt(room.id, %({"a":1}))

      restored = subject.load(crypto.dump("ignored"), "ignored")

      expect(restored.identity_keys).to be == crypto.identity_keys
      expect(restored.session_for(room.id)[:session_id]).to be == session[:session_id]
      expect(restored.decrypt(room.id, session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end
  end
end
