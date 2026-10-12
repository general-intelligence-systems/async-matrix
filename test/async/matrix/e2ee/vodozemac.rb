# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/vodozemac"

# Real encryption, so nothing here needs a homeserver: two devices and the keys they exchange are the whole subject.
describe Async::Matrix::E2EE::Vodozemac do
  # A pickle key is a key rather than a passphrase, so it is exactly 32 bytes.
  let(:pickle_key) {"0" * 32}

  let(:crypto) {subject.new}

  let(:other) {subject.new}

  # Open a session from one device to another, the way claiming a one time key does.
  def session_between(from, to)
    to.generate_one_time_keys(1)

    from.open_session(identity_key: to.identity_keys[:curve25519], one_time_key: to.one_time_keys.values.first)
  end

  with "#identity_keys" do
    it "answers a long lived key for each algorithm it signs and encrypts with" do
      expect(crypto.identity_keys.keys).to be == [:curve25519, :ed25519]
      expect(crypto.identity_keys[:curve25519]).not.to be == crypto.identity_keys[:ed25519]
    end

    it "answers keys of its own, which no other device shares" do
      expect(crypto.identity_keys).not.to be == other.identity_keys
    end
  end

  with "#algorithms" do
    # A device which did not offer Olm could never be sent a room key, because that is what carries one.
    it "offers both ratchets, because the room keys travel over Olm" do
      expect(crypto.algorithms).to be == [subject::OLM, subject::MEGOLM]
    end
  end

  with "#sign" do
    it "signs the canonical form, so that the order keys were given in does not matter" do
      expect(crypto.sign({a: 1, b: 2})).to be == crypto.sign({b: 2, a: 1})
    end

    it "verifies what another device signed" do
      signature = crypto.sign({a: 1})

      expect(other.verify({a: 1}, key: crypto.identity_keys[:ed25519], signature: signature)).to be == true
    end

    it "refuses a signature over something else" do
      signature = crypto.sign({a: 1})

      expect(other.verify({a: 2}, key: crypto.identity_keys[:ed25519], signature: signature)).to be == false
    end
  end

  with "#one_time_keys" do
    it "names each key as a server claims it" do
      crypto.generate_one_time_keys(2)

      expect(crypto.one_time_keys.size).to be == 2
      expect(crypto.one_time_keys.keys.first).to be(:start_with?, "#{subject::ALGORITHM}:")
    end

    # A key published twice would be claimed twice, and the session built on it read by whoever claimed it second.
    it "forgets the keys which were published" do
      crypto.generate_one_time_keys(2)
      crypto.published_one_time_keys!

      expect(crypto.one_time_keys).to be(:empty?)
    end

    it "keeps room to publish more before the server runs out" do
      expect(crypto.one_time_key_target).to be > 0
    end
  end

  with "#generate_fallback_key" do
    # It is handed out once the one time keys are exhausted, so a device is reachable even when it is offline.
    it "generates a key which the server may hand out more than once" do
      expect(crypto.fallback_key).to be(:empty?)

      crypto.generate_fallback_key

      expect(crypto.fallback_key.size).to be == 1
      expect(crypto.fallback_key.keys.first).to be(:start_with?, "#{subject::ALGORITHM}:")
    end
  end

  with "#open_session" do
    it "has no session with a device it has not claimed a key for" do
      expect(crypto.session?(other.identity_keys[:curve25519])).to be == false
    end

    it "opens a session from a claimed one time key" do
      session_id = self.session_between(crypto, other)

      expect(session_id).not.to be_nil
      expect(crypto.session?(other.identity_keys[:curve25519])).to be == true
    end
  end

  with "#encrypt_to_device" do
    # This is what carries every key: a room key is an Olm message before it is anything else.
    it "writes a pre-key message, which the other device adopts as a session" do
      self.session_between(crypto, other)

      type, body = crypto.encrypt_to_device(other.identity_keys[:curve25519], %({"type":"m.room_key"}))

      expect(type).to be == 0
      expect(other.accept_session(identity_key: crypto.identity_keys[:curve25519], body: body)).to be == %({"type":"m.room_key"})
    end

    # Olm sends pre-key messages until one arrives over the session, which is how the other side knows to keep it.
    it "writes a normal message once the session has carried one back" do
      self.session_between(crypto, other)

      _, first = crypto.encrypt_to_device(other.identity_keys[:curve25519], %({"a":1}))
      other.accept_session(identity_key: crypto.identity_keys[:curve25519], body: first)

      # The answer is a normal message already, because the session it goes over has received one.
      answered, answer = other.encrypt_to_device(crypto.identity_keys[:curve25519], %({"b":2}))
      crypto.decrypt_from_device(other.identity_keys[:curve25519], type: answered, body: answer)

      type, _ = crypto.encrypt_to_device(other.identity_keys[:curve25519], %({"c":3}))

      expect(answered).to be == 1
      expect(type).to be == 1
    end

    it "refuses a device it has no session with" do
      expect do
        crypto.encrypt_to_device(other.identity_keys[:curve25519], %({"a":1}))
      end.to raise_exception(KeyError)
    end
  end

  with "#decrypt_from_device" do
    it "reads what a device wrote over the session it opened" do
      self.session_between(crypto, other)

      _, body = crypto.encrypt_to_device(other.identity_keys[:curve25519], %({"a":1}))
      other.accept_session(identity_key: crypto.identity_keys[:curve25519], body: body)

      type, answer = other.encrypt_to_device(crypto.identity_keys[:curve25519], %({"b":2}))

      expect(crypto.decrypt_from_device(other.identity_keys[:curve25519], type: type, body: answer)).to be == %({"b":2})
    end

    it "refuses a message no session of its own can read" do
      self.session_between(crypto, other)

      expect do
        crypto.decrypt_from_device(other.identity_keys[:curve25519], type: 1, body: "AwogZm9v")
      end.to raise_exception(ArgumentError)
    end
  end

  with "#create_outbound_session" do
    it "answers a session and the key which shares it" do
      session = crypto.create_outbound_session("!room:localhost")

      expect(session[:session_id]).not.to be_nil
      expect(crypto.session_for("!room:localhost")[:session_id]).to be == session[:session_id]
    end

    it "has no session for a room it has not begun one for" do
      expect(crypto.session_for("!other:localhost")).to be_nil
    end

    it "begins a distinct session for each room" do
      first = crypto.create_outbound_session("!one:localhost")
      second = crypto.create_outbound_session("!two:localhost")

      expect(first[:session_id]).not.to be == second[:session_id]
    end
  end

  with "#decrypt" do
    it "reads what another device wrote, once its session has been accepted" do
      session = other.create_outbound_session("!room:localhost")
      ciphertext = other.encrypt("!room:localhost", %({"a":1}))

      crypto.create_inbound_session("!room:localhost", session_id: session[:session_id], session_key: session[:session_key])

      expect(crypto.decrypt("!room:localhost", session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    # A client shows the messages it sent, which come back in a sync batch like anybody else's.
    it "reads its own messages, without being given its own session" do
      session = crypto.create_outbound_session("!room:localhost")
      ciphertext = crypto.encrypt("!room:localhost", %({"a":1}))

      expect(crypto.decrypt("!room:localhost", session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    # The index is what a replayed message is recognised by, so it must count the messages.
    it "answers the index each message was sent at" do
      session = crypto.create_outbound_session("!room:localhost")
      crypto.encrypt("!room:localhost", %({"a":1}))
      second = crypto.encrypt("!room:localhost", %({"b":2}))

      expect(crypto.decrypt("!room:localhost", session_id: session[:session_id], ciphertext: second)).to be == [%({"b":2}), 1]
    end

    it "refuses a session it was never given" do
      ciphertext = crypto.create_outbound_session("!room:localhost").then do
        crypto.encrypt("!room:localhost", %({"a":1}))
      end

      expect do
        crypto.decrypt("!room:localhost", session_id: "never", ciphertext: ciphertext)
      end.to raise_exception(KeyError)
    end

    # The room is carried by the session rather than by the event, which is what stops a homeserver moving a message.
    it "refuses a message said to come from another room" do
      session = crypto.create_outbound_session("!room:localhost")
      ciphertext = crypto.encrypt("!room:localhost", %({"a":1}))

      expect do
        crypto.decrypt("!elsewhere:localhost", session_id: session[:session_id], ciphertext: ciphertext)
      end.to raise_exception(ArgumentError)
    end
  end

  with "#export_session" do
    # This is the format a key travels in when forwarded, backed up, or exported: version 1, and unsigned.
    it "exports a session another device can import" do
      session = crypto.create_outbound_session("!room:localhost")
      ciphertext = crypto.encrypt("!room:localhost", %({"a":1}))
      exported = crypto.export_session(session[:session_id], index: 0)

      other.import_inbound_session("!room:localhost", session_id: session[:session_id], exported_key: exported)

      expect(other.decrypt("!room:localhost", session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"a":1}), 0]
    end

    # Megolm ratchets forward only, so a key for an earlier message cannot be produced from a later one.
    it "cannot export a session from before where it begins" do
      session = crypto.create_outbound_session("!room:localhost")
      crypto.encrypt("!room:localhost", %({"a":1}))
      exported = crypto.export_session(session[:session_id], index: 1)

      other.import_inbound_session("!room:localhost", session_id: session[:session_id], exported_key: exported)

      expect(other.export_session(session[:session_id], index: 0)).to be_nil
    end
  end

  with "#dump" do
    # A device which forgot its sessions on restart would lose every message it had already been sent the key for.
    it "restores the identity it was dumped with" do
      restored = subject.load(crypto.dump(pickle_key), pickle_key)

      expect(restored.identity_keys).to be == crypto.identity_keys
    end

    it "restores the sessions it holds with other devices" do
      self.session_between(crypto, other)

      restored = subject.load(crypto.dump(pickle_key), pickle_key)

      expect(restored.session?(other.identity_keys[:curve25519])).to be == true
    end

    # The index must survive too, or a restored device would encrypt twice at the same one.
    it "restores a room's session where it left off" do
      session = crypto.create_outbound_session("!room:localhost")
      crypto.encrypt("!room:localhost", %({"a":1}))

      restored = subject.load(crypto.dump(pickle_key), pickle_key)
      ciphertext = restored.encrypt("!room:localhost", %({"b":2}))

      expect(restored.session_for("!room:localhost")[:session_id]).to be == session[:session_id]
      expect(restored.decrypt("!room:localhost", session_id: session[:session_id], ciphertext: ciphertext)).to be == [%({"b":2}), 1]
    end

    # Silently padding a short key would mean encrypting every secret this device holds with a weaker one.
    it "refuses a key which is not the length a key is" do
      expect{crypto.dump("too short")}.to raise_exception(RuntimeError)
    end
  end

  # The binding defines these, so they are tested beside it rather than in a file of their own.
  with Async::Matrix::E2EE::Sas do
    let(:ours) {Async::Matrix::E2EE::Sas.new}

    let(:theirs) {Async::Matrix::E2EE::Sas.new}

    # The info strings the specification defines are built from both keys, so an established channel must name both.
    it "names both public keys, and agrees with the other side about which is which" do
      our_key, their_key = ours.public_key, theirs.public_key

      established = ours.diffie_hellman(their_key)
      other = theirs.diffie_hellman(our_key)

      expect(established.our_public_key).to be == our_key
      expect(established.their_public_key).to be == their_key
      expect(other.our_public_key).to be == their_key
      expect(other.their_public_key).to be == our_key
    end

    # A caller can therefore build the info string from the channel alone, and both sides build the same one.
    it "agrees on the short authentication string" do
      established = ours.diffie_hellman(theirs.public_key)
      other = theirs.diffie_hellman(ours.public_key)

      info = "MATRIX_KEY_VERIFICATION_SAS|@a:localhost|AAA|#{established.our_public_key}|@b:localhost|BBB|#{established.their_public_key}|txn"

      expect(established.decimals(info)).to be == other.decimals(info)
      expect(established.emoji_indices(info)).to be == other.emoji_indices(info)
      expect(established.decimals(info).all?{|number| (1000..9191).cover?(number)}).to be == true
    end

    it "verifies a message authentication code the other side calculated" do
      established = ours.diffie_hellman(theirs.public_key)
      other = theirs.diffie_hellman(ours.public_key)

      mac = established.calculate_mac("ed25519:DEVICEID", "info")

      expect(other.verify_mac("ed25519:DEVICEID", "info", mac)).to be == true
      expect(other.verify_mac("ed25519:OTHERKEY", "info", mac)).to be == false
    end

    # One exchange establishes one secret, so a second attempt is a mistake rather than a thing to allow.
    it "cannot be established twice" do
      key = theirs.public_key
      ours.diffie_hellman(key)

      expect{ours.diffie_hellman(key)}.to raise_exception(RuntimeError)
    end
  end
end
