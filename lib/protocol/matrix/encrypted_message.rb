# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

require_relative "error"

module Protocol
  module Matrix
    # An `m.room.encrypted` event: parsed, identified, not yet readable.
    #
    # One event type carries two unrelated payload shapes, and `algorithm`
    # decides which you have:
    #
    #   m.olm.v1.curve25519-aes-sha2   to-device, 1:1. `ciphertext` is a MAP
    #                                  from each recipient's curve25519 identity
    #                                  key to `{"type" =>, "body" =>}`, so one
    #                                  event addresses several devices and only
    #                                  the entry under our own key is ours.
    #   m.megolm.v1.aes-sha2           room events, 1:many. `ciphertext` is a
    #                                  single string and `session_id` names the
    #                                  megolm session that can read it.
    #
    # THIS CLASS IS THE FORMAT AND NOTHING ELSE. It parses, it says what it is,
    # it hands its ciphertext to a session you supply, and it never holds a key,
    # opens a session or reads storage. Two things follow: it is unit testable
    # with a Hash and no crypto, and it cannot be the reason a key is used
    # against the wrong message.
    #
    #   message = EncryptedMessage.new(event)
    #   message.megolm?          # => true
    #   message.decrypted?       # => false
    #   message.decrypt!(session)
    #   message.type             # => "m.room.message" — the REAL type
    #   message.content          # => the plaintext content
    #
    # Both halves stay reachable: #encrypted_content is the envelope as it
    # arrived, #content is the plaintext. An undecryptable message is still a
    # perfectly good object -- a message whose room key has not arrived yet is
    # the single most common state in an encrypted room, not an error.
    class EncryptedMessage
      # The schema's algorithm enum for m.room.encrypted.
      OLM    = "m.olm.v1.curve25519-aes-sha2"
      MEGOLM = "m.megolm.v1.aes-sha2"

      ALGORITHMS = [OLM, MEGOLM].freeze

      # Olm message types. A PREKEY message carries enough to establish a NEW
      # inbound session, and consumes one of our one-time keys doing it; a
      # MESSAGE can only be read by a session that already exists.
      PREKEY  = 0
      MESSAGE = 1

      # The OlmPayload schema's required set. These fields sit INSIDE the
      # ciphertext, which is what makes an Olm message attributable at all: a
      # sender cannot forge them for a session it does not hold, so comparing
      # them against who we expected is what stops one device claiming to be
      # another. Verifying the values needs identities this class does not have;
      # refusing a payload that omits them does not.
      OLM_PAYLOAD_REQUIRED = %w[type content sender recipient recipient_keys keys].freeze

      # A message that does not match the format its own algorithm demands.
      class MalformedError < Error; end

      # An algorithm this library does not implement. NOT fatal to a batch: an
      # unknown algorithm is a message we cannot read, which is the same
      # practical state as a missing key.
      class UnsupportedAlgorithmError < Error; end

      # An Olm event whose ciphertext map has no entry for our identity key.
      class NotAddressedError < Error; end

      # The cryptography itself refused the message: a corrupt ciphertext, a
      # session that cannot read it, a ratchet too far advanced. Wrapped rather
      # than propagated so a caller rescues one protocol error instead of
      # whichever RuntimeError the vodozemac binding happened to raise.
      class DecryptionError < Error; end

      # #payload, #type, #content or #message_index asked for before #decrypt!.
      class NotDecryptedError < Error; end

      # Does this event need decrypting at all? Lets a caller sort a mixed batch
      # without rescuing.
      def self.encrypted?(data)
        data["type"] == "m.room.encrypted"
      end

      # ── Building ────────────────────────────────────────────────────────────
      #
      # The outgoing side of the same two formats. These produce the `content`
      # of an `m.room.encrypted` event from ciphertext somebody else computed,
      # which keeps the envelope rules in one place for both directions.

      # Megolm content, for a room event.
      #
      # `sender_key` and `device_id` ARE included, even though #sender_key and
      # #device_id refuse to return them when reading. That asymmetry is the
      # spec's: since Matrix 1.3 they "must not be read from" for Megolm, but
      # "should still be included on outgoing messages" -- older clients look
      # for them, and omitting them breaks those while reading them breaks us.
      def self.megolm_content(ciphertext:, session_id:, sender_key: nil, device_id: nil)
        {
          "algorithm"  => MEGOLM,
          "ciphertext" => ciphertext,
          "session_id" => session_id,
        }.tap do |content|
          if sender_key
            content["sender_key"] = sender_key
          end

          if device_id
            content["device_id"] = device_id
          end
        end
      end

      # Olm content, for a to-device message. `ciphertext` maps each recipient's
      # curve25519 identity key to its own `{"type" =>, "body" =>}`, so one event
      # can address many devices.
      def self.olm_content(sender_key:, ciphertext:)
        {
          "algorithm"  => OLM,
          "ciphertext" => ciphertext,
          "sender_key" => sender_key,
        }
      end

      # One entry in an Olm ciphertext map.
      def self.olm_ciphertext(type:, body:)
        {"type" => type, "body" => body}
      end

      # The plaintext a Megolm room event encrypts.
      #
      # THE ROOM ID IS INSIDE. That is what lets a recipient detect a message
      # moved between rooms: the envelope says one thing, the ciphertext says
      # another, and only the sender could have made them agree.
      def self.room_payload(type:, content:, room_id:)
        {"type" => type, "content" => content, "room_id" => room_id}
      end

      # The plaintext an Olm to-device message encrypts, with every field the
      # OlmPayload schema requires.
      #
      # These are what make the message attributable: they sit inside the
      # ciphertext, so a sender cannot forge them for a session it does not
      # hold, and the recipient compares them against who it expected.
      def self.olm_payload(type:, content:, sender:, sender_key:, recipient:, recipient_key:)
        {
          "type"           => type,
          "content"        => content,
          "sender"         => sender,
          "keys"           => {"ed25519" => sender_key},
          "recipient"      => recipient,
          "recipient_keys" => {"ed25519" => recipient_key},
        }
      end

      # The `m.room_key` payload that hands a Megolm session to another device.
      def self.room_key_payload(room_id:, session_id:, session_key:)
        {
          "type"    => "m.room_key",
          "content" => {
            "algorithm"   => MEGOLM,
            "room_id"     => room_id,
            "session_id"  => session_id,
            "session_key" => session_key,
          },
        }
      end

      # @parameter data [Hash] the raw event with string keys, exactly as it
      #   arrived. A to-device event has no `room_id`, `event_id` or
      #   `origin_server_ts`; a room event has all three. Both are valid.
      def initialize(data)
        @raw = data
        @encrypted_content = data["content"] || {}

        @algorithm  = @encrypted_content["algorithm"]
        @ciphertext = @encrypted_content["ciphertext"]
        @session_id = @encrypted_content["session_id"]

        @event_id         = data["event_id"]
        @room_id          = data["room_id"]
        @sender           = data["sender"]
        @origin_server_ts = data["origin_server_ts"]

        @decrypted = false
        @payload = nil
        @message_index = nil
      end

      attr_reader :raw,
        :encrypted_content,
        :algorithm,
        :ciphertext,
        :event_id,
        :room_id,
        :sender,
        :origin_server_ts

      # The counterpart of Event#encrypted?, so a batch can yield both kinds and
      # a consumer can read either without a type check.
      def encrypted? = true

      def olm? = @algorithm == OLM
      def megolm? = @algorithm == MEGOLM
      def supported? = ALGORITHMS.include?(@algorithm)

      # The megolm session that can read this, or nil for Olm. THE ONLY
      # legitimate way to find one -- see #sender_key for why the other
      # candidate field is not.
      def session_id
        if megolm?
          @session_id
        end
      end

      # The sender's curve25519 identity key -- Olm only, deliberately.
      #
      # Megolm events still carry `sender_key` on the wire and senders are still
      # told to include it, but since Matrix 1.3 the spec says it "must not be
      # read from if the encrypted event is using Megolm" and "must not be used
      # to find the corresponding session". Returning nil is how that MUST NOT
      # becomes unreachable instead of a comment; what arrived is still visible
      # through #encrypted_content.
      def sender_key
        unless megolm?
          @encrypted_content["sender_key"]
        end
      end

      # The sending device id -- Olm only, for the same reason as #sender_key.
      def device_id
        unless megolm?
          @encrypted_content["device_id"]
        end
      end

      # ── Olm addressing ──────────────────────────────────────────────────────

      # The `{"type" =>, "body" =>}` addressed to +identity_key+, or nil.
      def ciphertext_for(identity_key)
        if olm? && @ciphertext.is_a?(Hash)
          @ciphertext[identity_key]
        end
      end

      def addressed_to?(identity_key)
        !ciphertext_for(identity_key).nil?
      end

      # Every identity key this event addresses.
      def recipients
        if olm? && @ciphertext.is_a?(Hash)
          @ciphertext.keys
        else
          []
        end
      end

      # PREKEY (0) or MESSAGE (1) for +identity_key+, or nil if not addressed.
      def message_type(identity_key)
        info = ciphertext_for(identity_key)

        if info
          info["type"]
        end
      end

      # Does reading this require establishing a new inbound session, and so
      # consuming a one-time key?
      def prekey?(identity_key)
        message_type(identity_key) == PREKEY
      end

      # ── Validation ──────────────────────────────────────────────────────────

      def valid?
        validate!
        true
      rescue Error
        false
      end

      # @raises [MalformedError] a required field is absent, or the ciphertext is
      #   the wrong shape for the algorithm.
      # @raises [UnsupportedAlgorithmError] an algorithm we do not implement.
      def validate!
        if @algorithm.nil?
          raise MalformedError, "m.room.encrypted with no algorithm"
        end

        if @ciphertext.nil?
          raise MalformedError, "#{@algorithm} with no ciphertext"
        end

        unless supported?
          raise UnsupportedAlgorithmError, "unsupported algorithm: #{@algorithm}"
        end

        if megolm?
          validate_megolm!
        else
          validate_olm!
        end

        true
      end

      # ── Decryption ──────────────────────────────────────────────────────────

      def decrypted? = @decrypted

      # Read this message with +session+, which is whichever session the
      # algorithm calls for:
      #
      #   megolm   an inbound group session whose id is #session_id, answering
      #            `decrypt(ciphertext) -> [plaintext, message_index]`
      #   olm      a 1:1 session with #sender_key, answering
      #            `decrypt(type, body) -> plaintext`
      #
      # A SESSION, NOT A KEY. Both algorithms ratchet, so reading advances state
      # that belongs to the caller. This class never holds that state and never
      # saves it: after a successful call the caller must persist the session it
      # passed in, or the next message desynchronises.
      #
      # IDEMPOTENT. A second call returns the first payload rather than
      # decrypting again, because a second `session.decrypt` would ratchet the
      # session forward for a message that has already been read.
      #
      # @parameter identity_key [String] our own curve25519 key. Required for
      #   Olm, to pick our entry out of the ciphertext map; ignored for megolm.
      # @returns [Hash] the decrypted payload.
      def decrypt!(session, identity_key: nil)
        if @decrypted
          @payload
        else
          validate!
          @payload = decrypt_with(session, identity_key)
          @decrypted = true
          @payload
        end
      end

      # The decrypted payload: `{"type" =>, "content" =>, ...}`.
      def payload
        unless @decrypted
          raise NotDecryptedError, "message has not been decrypted"
        end

        @payload
      end

      # The REAL event type, which exists only once decrypted -- the envelope's
      # own type is always "m.room.encrypted" and must never reach a consumer.
      def type = payload["type"]

      def content = payload["content"] || {}

      # The room the PAYLOAD claims. Megolm payloads carry their own `room_id`,
      # and a sender whose payload disagrees with the envelope is trying to move
      # a message between rooms -- so both are kept rather than merged.
      def payload_room_id = payload["room_id"]

      # The megolm message index this event decrypted at.
      #
      # THE CALLER MUST CHECK IT. The spec: a client "should remember the megolm
      # `message_index` ... of each event they decrypt for each session" and
      # treat a repeat as invalid unless `event_id` and `origin_server_ts` also
      # match -- which is what makes a message replayed under a fresh event id
      # detectable. This class surfaces the index; it cannot do the remembering,
      # because remembering is storage.
      def message_index
        unless @decrypted
          raise NotDecryptedError, "message has not been decrypted"
        end

        @message_index
      end

      private

        def validate_megolm!
          unless @ciphertext.is_a?(String)
            raise MalformedError, "megolm ciphertext must be a string"
          end

          if @session_id.nil?
            raise MalformedError, "megolm event with no session_id"
          end
        end

        def validate_olm!
          unless @ciphertext.is_a?(Hash)
            raise MalformedError, "olm ciphertext must be a map of recipient keys"
          end

          # Not deprecated for Olm: this is how the recipient finds the session.
          if @encrypted_content["sender_key"].nil?
            raise MalformedError, "olm event with no sender_key"
          end
        end

        # ONE BRANCH PER ALGORITHM, in the shape protocol-grpc uses for content
        # encodings (Body::Readable#decompress): dispatch on the format field,
        # wrap the primitive so a failure inside it surfaces as a protocol error,
        # and make an algorithm we do not implement a named error rather than a
        # silent nil. A third algorithm is a `when` clause and a method.
        def decrypt_with(session, identity_key)
          case @algorithm
          when MEGOLM
            decrypt_megolm(session)
          when OLM
            decrypt_olm(session, identity_key)
          else
            raise UnsupportedAlgorithmError, "unsupported algorithm: #{@algorithm.inspect}"
          end
        end

        def decrypt_megolm(session)
          plaintext, index = megolm_plaintext(session)
          @message_index = index
          payload = parse(plaintext)

          unless payload.key?("type") && payload.key?("content")
            raise MalformedError, "megolm payload has no type/content"
          end

          payload
        end

        # Returns [plaintext, message_index].
        def megolm_plaintext(session)
          session.decrypt(@ciphertext)
        rescue StandardError => e
          raise DecryptionError, "failed to decrypt megolm message: #{e.class}: #{e.message}"
        end

        def decrypt_olm(session, identity_key)
          if identity_key.nil?
            raise ArgumentError, "identity_key is required to decrypt an olm message"
          end

          info = ciphertext_for(identity_key)

          if info.nil?
            raise NotAddressedError, "olm event is not addressed to #{identity_key}"
          end

          payload = parse(olm_plaintext(session, info))
          missing = OLM_PAYLOAD_REQUIRED.reject { |field| payload.key?(field) }

          unless missing.empty?
            raise MalformedError, "olm payload is missing #{missing.join(', ')}"
          end

          payload
        end

        def olm_plaintext(session, info)
          session.decrypt(info["type"], info["body"])
        rescue StandardError => e
          raise DecryptionError, "failed to decrypt olm message: #{e.class}: #{e.message}"
        end

        def parse(plaintext)
          JSON.parse(plaintext)
        rescue JSON::ParserError => e
          raise MalformedError, "decrypted payload was not JSON: #{e.message}"
        end
    end
  end
end

__END__
  describe "Protocol::Matrix::EncryptedMessage" do
    # Session doubles. The format object holds no keys and opens no sessions, so
    # every shape below is testable with no crypto at all -- which is the point
    # of the class existing separately from the machine that drives it.
    def megolm_session(plaintext, index = 0)
      calls = 0
      session = Object.new
      session.define_singleton_method(:decrypt) do |_ciphertext|
        calls += 1
        [plaintext, index]
      end
      session.define_singleton_method(:calls) { calls }
      session
    end

    def olm_session(plaintext)
      received = []
      session = Object.new
      session.define_singleton_method(:decrypt) do |type, body|
        received << [type, body]
        plaintext
      end
      session.define_singleton_method(:received) { received }
      session
    end

    def exploding_session(message = "BAD_MESSAGE_MAC")
      session = Object.new
      session.define_singleton_method(:decrypt) { |*| raise(RuntimeError, message) }
      session
    end

    def our_key = "7qZcfnBmbEGzxxaWfBjElJuvn7BZx+lSz/SvFrDF/z8"

    def megolm_event(content_overrides = {})
      {
        "type" => "m.room.encrypted",
        "event_id" => "$evt1",
        "room_id" => "!room:example.org",
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1234567890,
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "ciphertext" => "AwgAEnACgAkLmt6qF84IK++J7UDH2Za1YVchHyprqTqsg",
          "session_id" => "X3lUlvLELLYxeTx4yOVu6UDpasGEVO0Jbu+QFnm0cKQ",
        }.merge(content_overrides),
      }
    end

    def olm_event(content_overrides = {})
      {
        "type" => "m.room.encrypted",
        "sender" => "@bob:example.org",
        "content" => {
          "algorithm" => "m.olm.v1.curve25519-aes-sha2",
          "sender_key" => "Szl29ksW/L8yZGWAX+8dY1XyFi+i5wm+DRhTGkbMiwU",
          "ciphertext" => {
            our_key => {
              "type" => 0,
              "body" => "AwogGJJzMhf/S3GQFXAOrCZ3iKyGU5ZScVtjI0KypTYrW",
            },
          },
        }.merge(content_overrides),
      }
    end

    def megolm_payload
      JSON.generate({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
        "room_id" => "!room:example.org",
      })
    end

    def olm_payload(overrides = {})
      JSON.generate({
        "type" => "m.room_key",
        "content" => {"algorithm" => "m.megolm.v1.aes-sha2"},
        "sender" => "@bob:example.org",
        "recipient" => "@alice:example.org",
        "recipient_keys" => {"ed25519" => "ours"},
        "keys" => {"ed25519" => "theirs"},
      }.merge(overrides))
    end

    def message_for(event) = Protocol::Matrix::EncryptedMessage.new(event)

    # ── Identifying the format ────────────────────────────────────────────────

    it "recognises an event that needs decrypting" do
      Protocol::Matrix::EncryptedMessage.encrypted?(megolm_event).should == true
      Protocol::Matrix::EncryptedMessage.encrypted?({"type" => "m.room.message"}).should == false
    end

    it "identifies a megolm event" do
      message = message_for(megolm_event)

      message.megolm?.should == true
      message.olm?.should == false
      message.supported?.should == true
      message.valid?.should == true
    end

    it "identifies an olm event" do
      message = message_for(olm_event)

      message.olm?.should == true
      message.megolm?.should == false
      message.supported?.should == true
      message.valid?.should == true
    end

    it "carries the envelope of a room event" do
      message = message_for(megolm_event)

      message.event_id.should == "$evt1"
      message.room_id.should == "!room:example.org"
      message.sender.should == "@alice:example.org"
      message.origin_server_ts.should == 1234567890
    end

    # A to-device event is the same event type with no room envelope at all.
    it "accepts a to-device event with no room envelope" do
      message = message_for(olm_event)

      message.event_id.should.be.nil
      message.room_id.should.be.nil
      message.origin_server_ts.should.be.nil
      message.valid?.should == true
    end

    # ── Megolm session lookup, and the deprecated fields ──────────────────────

    it "exposes session_id for megolm" do
      message_for(megolm_event).session_id
        .should == "X3lUlvLELLYxeTx4yOVu6UDpasGEVO0Jbu+QFnm0cKQ"
    end

    # Matrix 1.3: sender_key and device_id "must not be read from if the
    # encrypted event is using Megolm", and must not be used to find the session.
    it "refuses to surface sender_key or device_id for megolm, even when present" do
      message = message_for(
        megolm_event(
          "sender_key" => "IlRMeOPX2e0MurIyfWEucYBRVOEEUMrOHqn/8mLqMjA",
          "device_id" => "RJYKSTBOIE",
        ),
      )

      message.sender_key.should.be.nil
      message.device_id.should.be.nil
      message.encrypted_content["sender_key"].should == "IlRMeOPX2e0MurIyfWEucYBRVOEEUMrOHqn/8mLqMjA"
    end

    it "accepts a megolm event carrying neither deprecated field" do
      message_for(megolm_event).valid?.should == true
    end

    it "has no session_id for olm" do
      message_for(olm_event).session_id.should.be.nil
    end

    it "exposes sender_key for olm, where it is not deprecated" do
      message_for(olm_event).sender_key
        .should == "Szl29ksW/L8yZGWAX+8dY1XyFi+i5wm+DRhTGkbMiwU"
    end

    # ── Olm addressing ────────────────────────────────────────────────────────

    it "finds the ciphertext addressed to us" do
      message = message_for(olm_event)

      message.addressed_to?(our_key).should == true
      message.ciphertext_for(our_key)["type"].should == 0
      message.recipients.should == [our_key]
    end

    it "reports an event addressed to a different device" do
      message = message_for(olm_event)

      message.addressed_to?("someone-elses-key").should == false
      message.ciphertext_for("someone-elses-key").should.be.nil
      message.message_type("someone-elses-key").should.be.nil
    end

    it "handles an event addressed to several devices at once" do
      message = message_for(
        olm_event(
          "ciphertext" => {
            our_key => {"type" => 1, "body" => "ours"},
            "another-device-key" => {"type" => 0, "body" => "theirs"},
          },
        ),
      )

      message.recipients.length.should == 2
      message.ciphertext_for(our_key)["body"].should == "ours"
      message.message_type("another-device-key").should == 0
    end

    it "distinguishes a prekey message from an ordinary one" do
      prekey = message_for(olm_event)
      prekey.message_type(our_key).should == Protocol::Matrix::EncryptedMessage::PREKEY
      prekey.prekey?(our_key).should == true

      ordinary = message_for(olm_event("ciphertext" => {our_key => {"type" => 1, "body" => "b"}}))
      ordinary.message_type(our_key).should == Protocol::Matrix::EncryptedMessage::MESSAGE
      ordinary.prekey?(our_key).should == false
    end

    it "has no olm addressing for a megolm event" do
      message = message_for(megolm_event)

      message.recipients.should == []
      message.ciphertext_for(our_key).should.be.nil
      message.addressed_to?(our_key).should == false
    end

    # ── Malformed and unsupported ─────────────────────────────────────────────

    it "rejects an event with no algorithm" do
      message = message_for({"content" => {"ciphertext" => "x"}})

      message.supported?.should == false
      message.valid?.should == false
      lambda { message.validate! }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    it "rejects an event with no ciphertext" do
      message = message_for({"content" => {"algorithm" => "m.megolm.v1.aes-sha2"}})

      lambda { message.validate! }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    # An unknown algorithm is not a crash: it is a message we cannot read, the
    # same practical state as a missing key.
    it "reports an unsupported algorithm without raising on construction" do
      message = message_for(olm_event("algorithm" => "m.megolm.v2.made-up"))

      message.supported?.should == false
      message.olm?.should == false
      message.megolm?.should == false
      message.valid?.should == false
      lambda {
        message.validate!
      }.should.raise(Protocol::Matrix::EncryptedMessage::UnsupportedAlgorithmError)
    end

    it "rejects a megolm event whose ciphertext is a recipient map" do
      message = message_for(megolm_event("ciphertext" => {our_key => {"type" => 0, "body" => "b"}}))

      lambda { message.validate! }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    it "rejects a megolm event with no session_id" do
      event = megolm_event
      event["content"].delete("session_id")

      lambda {
        message_for(event).validate!
      }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    it "rejects an olm event whose ciphertext is a bare string" do
      message = message_for(olm_event("ciphertext" => "not-a-map"))

      lambda { message.validate! }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    it "rejects an olm event with no sender_key" do
      event = olm_event
      event["content"].delete("sender_key")

      lambda {
        message_for(event).validate!
      }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    # ── Decrypting megolm ─────────────────────────────────────────────────────

    it "decrypts a megolm event through the session it is handed" do
      message = message_for(megolm_event)

      message.decrypted?.should == false
      message.decrypt!(megolm_session(megolm_payload, 7))

      message.decrypted?.should == true
      message.type.should == "m.room.message"
      message.content.should == {"msgtype" => "m.text", "body" => "hello"}
      message.payload_room_id.should == "!room:example.org"
      message.message_index.should == 7
    end

    # Both halves stay reachable: the envelope is evidence, not scaffolding.
    it "keeps the encrypted content after decrypting" do
      message = message_for(megolm_event)
      message.decrypt!(megolm_session(megolm_payload))

      message.encrypted_content["algorithm"].should == "m.megolm.v1.aes-sha2"
      message.ciphertext.should == "AwgAEnACgAkLmt6qF84IK++J7UDH2Za1YVchHyprqTqsg"
    end

    # A second decrypt would ratchet the session forward for a message already
    # read, so the first payload is returned instead.
    it "is idempotent and does not touch the session twice" do
      message = message_for(megolm_event)
      session = megolm_session(megolm_payload)

      first = message.decrypt!(session)
      second = message.decrypt!(session)

      second.should == first
      session.calls.should == 1
    end

    it "rejects a megolm payload with no type or content" do
      message = message_for(megolm_event)
      session = megolm_session(JSON.generate({"room_id" => "!r:example.org"}))

      lambda {
        message.decrypt!(session)
      }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    it "rejects a payload that is not JSON" do
      message = message_for(megolm_event)

      lambda {
        message.decrypt!(megolm_session("not json at all"))
      }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
    end

    # Whatever the cryptography raises becomes one protocol error, so a caller
    # rescues this rather than whichever RuntimeError the binding chose.
    it "wraps a failure inside the megolm primitive" do
      message = message_for(megolm_event)

      lambda {
        message.decrypt!(exploding_session)
      }.should.raise(Protocol::Matrix::EncryptedMessage::DecryptionError)
    end

    # ── Decrypting olm ────────────────────────────────────────────────────────

    it "decrypts an olm event with the entry addressed to us" do
      message = message_for(olm_event)
      session = olm_session(olm_payload)

      message.decrypt!(session, identity_key: our_key)

      session.received.should == [[0, "AwogGJJzMhf/S3GQFXAOrCZ3iKyGU5ZScVtjI0KypTYrW"]]
      message.type.should == "m.room_key"
      message.content.should == {"algorithm" => "m.megolm.v1.aes-sha2"}
    end

    it "has no message index for olm" do
      message = message_for(olm_event)
      message.decrypt!(olm_session(olm_payload), identity_key: our_key)

      message.message_index.should.be.nil
    end

    it "requires an identity key to decrypt olm" do
      message = message_for(olm_event)

      lambda { message.decrypt!(olm_session(olm_payload)) }.should.raise(ArgumentError)
    end

    it "refuses to decrypt an olm event not addressed to us" do
      message = message_for(olm_event)

      lambda {
        message.decrypt!(olm_session(olm_payload), identity_key: "not-our-key")
      }.should.raise(Protocol::Matrix::EncryptedMessage::NotAddressedError)
    end

    # The OlmPayload required set. These fields live inside the ciphertext, so
    # they are what makes an olm message attributable; a payload without them
    # cannot be checked against who we expected.
    it "rejects an olm payload missing any required field" do
      %w[type content sender recipient recipient_keys keys].each do |field|
        payload = JSON.parse(olm_payload)
        payload.delete(field)
        message = message_for(olm_event)

        lambda {
          message.decrypt!(olm_session(JSON.generate(payload)), identity_key: our_key)
        }.should.raise(Protocol::Matrix::EncryptedMessage::MalformedError)
      end
    end

    it "wraps a failure inside the olm primitive" do
      message = message_for(olm_event)

      lambda {
        message.decrypt!(exploding_session, identity_key: our_key)
      }.should.raise(Protocol::Matrix::EncryptedMessage::DecryptionError)
    end

    # ── Before decryption ─────────────────────────────────────────────────────

    it "raises rather than guessing when read before decryption" do
      message = message_for(megolm_event)

      lambda { message.payload }.should.raise(Protocol::Matrix::EncryptedMessage::NotDecryptedError)
      lambda { message.type }.should.raise(Protocol::Matrix::EncryptedMessage::NotDecryptedError)
      lambda { message.content }.should.raise(Protocol::Matrix::EncryptedMessage::NotDecryptedError)
      lambda {
        message.message_index
      }.should.raise(Protocol::Matrix::EncryptedMessage::NotDecryptedError)
    end

    it "validates before attempting to decrypt" do
      message = message_for(megolm_event("algorithm" => "made.up.algorithm"))

      lambda {
        message.decrypt!(megolm_session(megolm_payload))
      }.should.raise(Protocol::Matrix::EncryptedMessage::UnsupportedAlgorithmError)
    end
    # ── Building the outgoing side ────────────────────────────────────────────

    it "builds megolm content" do
      content = Protocol::Matrix::EncryptedMessage.megolm_content(
        ciphertext: "AwgAEnAC", session_id: "session1",
        sender_key: "ourcurve", device_id: "OURDEV",
      )

      content.should == {
        "algorithm" => "m.megolm.v1.aes-sha2",
        "ciphertext" => "AwgAEnAC",
        "session_id" => "session1",
        "sender_key" => "ourcurve",
        "device_id" => "OURDEV",
      }
    end

    # The spec's asymmetry: "must not be read from" for Megolm, but "should
    # still be included on outgoing messages".
    it "includes the deprecated fields outgoing, though it refuses to read them" do
      content = Protocol::Matrix::EncryptedMessage.megolm_content(
        ciphertext: "c", session_id: "s", sender_key: "ourcurve", device_id: "OURDEV",
      )
      message = Protocol::Matrix::EncryptedMessage.new(
        {"type" => "m.room.encrypted", "content" => content},
      )

      content["sender_key"].should == "ourcurve"
      message.sender_key.should.be.nil
    end

    it "omits the deprecated fields when not given them" do
      content = Protocol::Matrix::EncryptedMessage.megolm_content(ciphertext: "c", session_id: "s")

      content.key?("sender_key").should == false
      content.key?("device_id").should == false
    end

    it "builds olm content addressing several devices" do
      content = Protocol::Matrix::EncryptedMessage.olm_content(
        sender_key: "ourcurve",
        ciphertext: {
          "theirs" => Protocol::Matrix::EncryptedMessage.olm_ciphertext(type: 0, body: "b1"),
          "others" => Protocol::Matrix::EncryptedMessage.olm_ciphertext(type: 1, body: "b2"),
        },
      )
      message = Protocol::Matrix::EncryptedMessage.new(
        {"type" => "m.room.encrypted", "content" => content},
      )

      message.olm?.should == true
      message.recipients.sort.should == ["others", "theirs"]
      message.message_type("theirs").should == 0
      message.sender_key.should == "ourcurve"
    end

    it "builds content its own reader accepts" do
      megolm = Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "content" => Protocol::Matrix::EncryptedMessage.megolm_content(
          ciphertext: "c", session_id: "s",
        ),
      })
      olm = Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "content" => Protocol::Matrix::EncryptedMessage.olm_content(
          sender_key: "k",
          ciphertext: {"them" => Protocol::Matrix::EncryptedMessage.olm_ciphertext(type: 0, body: "b")},
        ),
      })

      megolm.valid?.should == true
      olm.valid?.should == true
    end

    # THE ROOM ID IS INSIDE the ciphertext, which is what lets a recipient catch
    # a message moved between rooms.
    it "puts the room id inside the megolm plaintext" do
      Protocol::Matrix::EncryptedMessage.room_payload(
        type: "m.room.message", content: {"body" => "hi"}, room_id: "!room:example.org",
      ).should == {
        "type" => "m.room.message",
        "content" => {"body" => "hi"},
        "room_id" => "!room:example.org",
      }
    end

    # Every field the OlmPayload schema requires -- which is also exactly what
    # #decrypt! refuses a payload for omitting.
    it "builds an olm payload with every required field" do
      payload = Protocol::Matrix::EncryptedMessage.olm_payload(
        type: "m.room_key", content: {"a" => 1},
        sender: "@us:example.org", sender_key: "oured",
        recipient: "@them:example.org", recipient_key: "theired",
      )

      payload.should == {
        "type" => "m.room_key",
        "content" => {"a" => 1},
        "sender" => "@us:example.org",
        "keys" => {"ed25519" => "oured"},
        "recipient" => "@them:example.org",
        "recipient_keys" => {"ed25519" => "theired"},
      }
      Protocol::Matrix::EncryptedMessage::OLM_PAYLOAD_REQUIRED.all? { |field| payload.key?(field) }
        .should == true
    end

    it "builds a room key payload" do
      Protocol::Matrix::EncryptedMessage.room_key_payload(
        room_id: "!room:example.org", session_id: "s1", session_key: "AgAAAAkey",
      ).should == {
        "type" => "m.room_key",
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "room_id" => "!room:example.org",
          "session_id" => "s1",
          "session_key" => "AgAAAAkey",
        },
      }
    end
  end
