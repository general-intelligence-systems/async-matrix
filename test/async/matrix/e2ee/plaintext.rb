# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/plaintext"

describe Async::Matrix::E2EE::Plaintext do
  let(:crypto) {subject.new}

  let(:room_id) {"!room:localhost"}

  with "#identity_keys" do
    it "answers a long lived key for each algorithm it signs and encrypts with" do
      expect(crypto.identity_keys.keys).to be == [:curve25519, :ed25519]
      expect(crypto.identity_keys[:curve25519]).not.to be == crypto.identity_keys[:ed25519]
    end

    it "answers the same keys every time, because they are this device's identity" do
      expect(crypto.identity_keys).to be == crypto.identity_keys
    end
  end

  with "#sign" do
    it "signs the canonical form, so that the order keys were given in does not matter" do
      expect(crypto.sign({a: 1, b: 2})).to be == crypto.sign({b: 2, a: 1})
    end

    it "signs different objects differently" do
      expect(crypto.sign({a: 1})).not.to be == crypto.sign({a: 2})
    end

    it "verifies what it signed" do
      object = {a: 1}

      expect(crypto.verify(object, key: crypto.identity_keys[:ed25519], signature: crypto.sign(object))).to be == true
    end

    it "does not verify a signature over something else" do
      expect(crypto.verify({a: 1}, key: "k", signature: crypto.sign({a: 2}))).to be == false
    end

    # Nothing here is a signature, and a caller which mistook one for a signature should be able to tell.
    it "says in the signature that it is not one" do
      expect(crypto.sign({a: 1})).to be(:start_with?, "#{subject::MARKER}:")
    end
  end

  with "#one_time_keys" do
    it "generates the number asked for" do
      expect(crypto.generate_one_time_keys(3).size).to be == 3
      expect(crypto.one_time_keys.size).to be == 3
    end

    it "keys them by the algorithm a server claims them with" do
      crypto.generate_one_time_keys(1)

      expect(crypto.one_time_keys.keys.first.to_s).to be(:start_with?, "signed_curve25519:")
    end

    it "accumulates keys which have not been published" do
      crypto.generate_one_time_keys(2)
      crypto.generate_one_time_keys(2)

      expect(crypto.one_time_keys.size).to be == 4
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
      session = crypto.create_outbound_session(room_id)

      expect(session[:session_id]).not.to be_nil
      expect(session[:session_key]).not.to be_nil
    end

    it "is then the session that room is encrypted with" do
      session = crypto.create_outbound_session(room_id)

      expect(crypto.session_for(room_id)).to be == session
    end

    it "has no session for a room it has not begun one for" do
      crypto.create_outbound_session(room_id)

      expect(crypto.session_for("!other:localhost")).to be_nil
    end

    it "begins a distinct session for each room" do
      first = crypto.create_outbound_session(room_id)
      second = crypto.create_outbound_session("!other:localhost")

      expect(first[:session_id]).not.to be == second[:session_id]
    end
  end

  with "#decrypt" do
    # The point of this implementation: the whole flow can be driven, because what it writes can be read back.
    it "reads back what it wrote, once the session has been accepted" do
      session = crypto.create_outbound_session(room_id)
      ciphertext = crypto.encrypt(room_id, %({"a":1}))

      crypto.create_inbound_session(room_id, session_id: session[:session_id], session_key: session[:session_key])

      expect(crypto.decrypt(room_id, session_id: session[:session_id], ciphertext: ciphertext)).to be == %({"a":1})
    end

    it "refuses a session it was never given" do
      ciphertext = crypto.encrypt(room_id, %({"a":1}))

      expect{crypto.decrypt(room_id, session_id: "never", ciphertext: ciphertext)}.to raise_exception(KeyError)
    end

    # A client shows the messages it sent, which come back in a sync batch like anybody else's.
    it "reads its own messages, without being given its own session" do
      session = crypto.create_outbound_session(room_id)
      ciphertext = crypto.encrypt(room_id, %({"a":1}))

      expect(crypto.decrypt(room_id, session_id: session[:session_id], ciphertext: ciphertext)).to be == %({"a":1})
    end

    it "refuses something another implementation wrote" do
      session = crypto.create_outbound_session(room_id)
      crypto.create_inbound_session(room_id, session_id: session[:session_id], session_key: session[:session_key])

      expect{crypto.decrypt(room_id, session_id: session[:session_id], ciphertext: "AwgAEnB0:xyz")}.to raise_exception(ArgumentError)
    end
  end

  with "#algorithms" do
    it "encrypts with megolm, as a room is encrypted" do
      expect(crypto.algorithms).to be == [subject::ALGORITHM]
    end
  end
end
