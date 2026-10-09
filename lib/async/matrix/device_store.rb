# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "digest"

require_relative "../../protocol/matrix/encrypted_message"
require_relative "../../protocol/matrix/keys"

module Async
  module Matrix
    # One device's key material, and the ability to read anything it holds a key
    # for.
    #
    # A CLIENT CLASS, NOT A PROTOCOL ONE. Protocol::Matrix owns formats and the
    # rules for reading them, and holds no state and no key material. This holds
    # both: a live Olm account, the ratchets, and every room key the device has
    # accumulated. It is also where the native crypto primitives are injected,
    # which the format layer must never name.
    #
    # This is what you hand to a sync client. It owns the Olm account, the 1:1
    # sessions with other devices, and every Megolm room key the device has been
    # given — so it can decrypt a message from ANY room, because a room key is
    # just an entry in here.
    #
    #   store = DeviceStore.new(
    #     user_id: "@bot:example.org", device_id: "ABCDEFGHIJ",
    #     account: account, e2ee: Async::Matrix::E2EE,
    #   )
    #
    #   store.decrypt(message)   # => message if it could be read, nil if not
    #
    # IT ACCUMULATES AS IT READS. Decrypting an Olm to-device message routinely
    # yields an `m.room_key`, and the store absorbs it on the spot. That is what
    # makes a sync loop work with no orchestration above it: feed the batch
    # through in order and the keys arriving early in it unlock the messages
    # later in it.
    #
    # NO PERSISTENCE, BY CONSTRUCTION. The primitives are handed in, already
    # unpickled, and every ratchet step is reported through #changes for the
    # caller to write wherever it likes. This class never sees a database, and
    # it holds no opinion about where its keys came from — which is also why it
    # can be driven in a test with three fake objects and no cryptography.
    #
    # THE PRIMITIVES ARE INJECTED. `account` is duck-typed, and `e2ee` is
    # whatever module provides InboundGroupSession. The protocol layer therefore
    # names no native extension and keeps its dependency list empty; the caller
    # decides which implementation backs it.
    class DeviceStore
      class Error < Protocol::Matrix::Errors::Error; end

      # The same message, delivered twice, with a different event id.
      class ReplayError < Error; end

      # A key issued for one room used against a message in another. Refused
      # rather than decrypted: a sender who can place a message in a room they
      # hold no key for could otherwise have it attributed to a room they do.
      class RoomMismatchError < Error; end

      # The store was asked to absorb a room key it cannot build, because no
      # primitive factory was supplied.
      class MissingPrimitivesError < Error; end

      # Rotation is a security property, not housekeeping: everyone holding the
      # current key can read everything encrypted with it, so a session must not
      # live forever. These are the spec defaults for m.room.encryption when the
      # room does not override them.
      DEFAULT_ROTATION_MESSAGES = 100
      DEFAULT_ROTATION_MS = 7 * 24 * 60 * 60 * 1000

      ROOM_KEY = "m.room_key"
      FORWARDED_ROOM_KEY = "m.forwarded_room_key"
      MEGOLM = Protocol::Matrix::EncryptedMessage::MEGOLM

      # @parameter account [Object] an unpickled Olm account, answering
      #   #curve25519_key, #ed25519_key, #sign and #create_inbound_session.
      # @parameter e2ee [Module] supplies InboundGroupSession, used to build a
      #   session from a received room key. Optional: a store that only ever
      #   reads keys handed to it directly does not need one.
      # @parameter olm_sessions [Hash] sender_key => [session, ...], most
      #   recently used first.
      # @parameter group_sessions [Hash] session_id => {session:, room_id:}.
      def initialize(user_id:, device_id:, account:, e2ee: nil, olm_sessions: {}, group_sessions: {})
        @user_id = user_id
        @device_id = device_id
        @account = account
        @e2ee = e2ee
        @olm_sessions = olm_sessions
        @group_sessions = group_sessions

        @outbound_sessions = {}
        @message_indexes = {}
        @olm_hashes = {}

        @changed_olm_sessions = []
        @changed_group_sessions = []
        @changed_outbound_rooms = []
        @account_changed = false
      end

      attr_reader :user_id, :device_id, :account

      # Our own curve25519 identity key: what other devices encrypt Olm messages
      # to, and the key an Olm ciphertext map is addressed under.
      def identity_key = @account.curve25519_key

      # Our own ed25519 key: what our signatures are verified against.
      def fingerprint = @account.ed25519_key

      # ── Publishing ──────────────────────────────────────────────────────────
      #
      # Until these are uploaded the device is unreachable: no peer can claim a
      # one-time key, so none can open an Olm session, so none can send us a
      # room key -- and every message in an encrypted room stays ciphertext
      # forever. Publication is not an optimisation; it is the precondition for
      # receiving anything at all.

      # This device's signed identity document, for POST /keys/upload.
      def device_keys
        Protocol::Matrix::Keys.device_keys(
          user_id:    @user_id,
          device_id:  @device_id,
          curve25519: identity_key,
          ed25519:    fingerprint,
          signer:     @account,
        )
      end

      # Generate +count+ one-time keys and return them signed, ready to upload.
      #
      # NOT MARKED PUBLISHED HERE. The account only forgets a key once
      # #mark_keys_published! is called, and calling that before the upload
      # succeeds would discard keys the server never received -- which looks,
      # later, exactly like a peer claiming a key we have no record of.
      def generate_one_time_keys(count = default_one_time_key_count)
        @account.generate_one_time_keys(count)
        @account_changed = true

        Protocol::Matrix::Keys.one_time_keys(
          @account.one_time_keys,
          user_id:   @user_id,
          device_id: @device_id,
          signer:    @account,
        )
      end

      # The fallback key, which answers claims once the one-time keys run out.
      # It is NOT consumed when used, which is what stops a peer who has
      # exhausted our keys being unable to reach us at all.
      def generate_fallback_key
        @account.generate_fallback_key
        @account_changed = true

        Protocol::Matrix::Keys.fallback_keys(
          @account.fallback_key,
          user_id:   @user_id,
          device_id: @device_id,
          signer:    @account,
        )
      end

      # Call this ONLY after the upload succeeded.
      def mark_keys_published!
        @account.mark_keys_as_published
        @account_changed = true
        self
      end

      # The spec suggests keeping around half of the maximum available, since a
      # device that runs out cannot be reached.
      def default_one_time_key_count
        @account.max_number_of_one_time_keys / 2
      end

      # Should we top up? Compared against what the SERVER last reported it
      # still holds, not against what we generated: keys are consumed by other
      # devices claiming them, which we never observe directly.
      def needs_one_time_keys?(server_count)
        server_count < default_one_time_key_count
      end

      # ── Reading ─────────────────────────────────────────────────────────────

      # Read +message+ with whatever key this store holds for it.
      #
      # @returns [EncryptedMessage | Nil] the message, decrypted, or nil when we
      #   hold no key for it.
      #
      # NIL IS NOT AN ERROR. A message whose room key has not arrived is the
      # single most common state in an encrypted room, and it is recoverable:
      # the key may turn up later in this batch, in a later one, or from backup.
      # Raising here would make the normal case exceptional and force every sync
      # loop to rescue it.
      def decrypt(message)
        case message.algorithm
        when MEGOLM
          decrypt_megolm(message)
        when Protocol::Matrix::EncryptedMessage::OLM
          decrypt_olm(message)
        else
          raise Protocol::Matrix::Errors::UnsupportedAlgorithmError,
            "unsupported algorithm: #{message.algorithm.inspect}"
        end
      end

      # ── Writing ─────────────────────────────────────────────────────────────

      # Encrypt a room event, rotating the session first if policy says so.
      #
      # @returns [Array] [content, session_id, targets_already_holding_the_key]
      #   The caller needs the last two: before this content can be read by
      #   anyone, the session key has to reach every device in the room that
      #   does not already have it, and only the caller can talk to the
      #   homeserver to do that.
      def encrypt(room_id:, type:, content:, rotation: {})
        entry = outbound_session(room_id, rotation: rotation)
        payload = Protocol::Matrix::EncryptedMessage.room_payload(
          type: type, content: content, room_id: room_id,
        )

        ciphertext = entry[:session].encrypt(JSON.generate(payload))
        entry[:message_count] += 1
        @changed_outbound_rooms << room_id

        [
          Protocol::Matrix::EncryptedMessage.megolm_content(
            ciphertext: ciphertext,
            session_id: entry[:session].session_id,
            sender_key: identity_key,
            device_id:  @device_id,
          ),
          entry[:session].session_id,
          entry[:shared_with],
        ]
      end

      # The live outbound session for a room, started or rotated as needed.
      def outbound_session(room_id, rotation: {})
        entry = @outbound_sessions[room_id]

        if entry.nil? || expired?(entry, rotation)
          rotate!(room_id)
        else
          entry
        end
      end

      # Start a fresh session for a room, discarding the old one.
      #
      # CALL THIS WHEN ANYONE LEAVES. Whoever left still holds the current key,
      # so every message encrypted with it afterwards would be readable by them;
      # rotation is the only thing that stops that, and no timer will do it in
      # time.
      def rotate!(room_id)
        if @e2ee.nil?
          raise MissingPrimitivesError, "no e2ee factory was supplied, so no session can be started"
        end

        session = @e2ee::GroupSession.new
        @changed_outbound_rooms << room_id

        @outbound_sessions[room_id] = {
          session:       session,
          started_at:    now_ms,
          message_count: 0,
          shared_with:   {},
        }
      end

      # The m.room_key payload handing a room's current session to someone else.
      #
      # ALSO STORED FOR OURSELVES. An outbound Megolm session cannot decrypt, so
      # without keeping the matching inbound session we could not read our own
      # messages back.
      def room_key_payload(room_id)
        entry = @outbound_sessions[room_id]

        if entry.nil?
          nil
        else
          session_key = entry[:session].session_key

          add_group_session(@e2ee::InboundGroupSession.new(session_key), room_id: room_id)

          Protocol::Matrix::EncryptedMessage.room_key_payload(
            room_id:     room_id,
            session_id:  entry[:session].session_id,
            session_key: session_key,
          )
        end
      end

      # Has this device already been given the room's current key? Re-sharing to
      # everyone on every message would be correct but wasteful.
      def shared_with?(room_id, matrix_user_id, device_id)
        entry = @outbound_sessions[room_id]

        if entry.nil?
          false
        else
          Array(entry[:shared_with][matrix_user_id]).include?(device_id)
        end
      end

      # Record that a set of devices now holds the room's current key.
      # +targets+ is { "@user:server" => ["DEVICEID", ...] }.
      def record_shared!(room_id, targets)
        @outbound_sessions[room_id].tap do |entry|
          unless entry.nil?
            targets.each do |matrix_user_id, device_ids|
              held = entry[:shared_with][matrix_user_id] || []
              entry[:shared_with][matrix_user_id] = held | Array(device_ids)
            end

            @changed_outbound_rooms << room_id
          end
        end
      end

      # Wrap a payload in Olm for one device.
      #
      # @parameter one_time_key [String] a claimed key, needed only when we have
      #   no session with this device yet. Without either, the device is
      #   unreachable and this answers nil rather than guessing.
      def encrypt_to_device(payload, recipient:, recipient_identity_key:, recipient_key:, one_time_key: nil)
        session = olm_sessions_with(recipient_identity_key).first ||
          open_outbound_session(recipient_identity_key, one_time_key)

        if session.nil?
          nil
        else
          body = Protocol::Matrix::EncryptedMessage.olm_payload(
            type:          payload["type"],
            content:       payload["content"],
            sender:        @user_id,
            sender_key:    fingerprint,
            recipient:     recipient,
            recipient_key: recipient_key,
          )

          type, ciphertext = session.encrypt(JSON.generate(body))
          @changed_olm_sessions << session.session_id

          Protocol::Matrix::EncryptedMessage.olm_content(
            sender_key: identity_key,
            ciphertext: {
              recipient_identity_key => Protocol::Matrix::EncryptedMessage.olm_ciphertext(
                type: type, body: ciphertext,
              ),
            },
          )
        end
      end

      # ── Room keys ───────────────────────────────────────────────────────────

      # Take a room key out of a decrypted to-device payload.
      #
      # Idempotent: the same key is commonly sent more than once -- a re-share,
      # or a second device forwarding it -- and the session already held is the
      # one further back in the ratchet, so replacing it would LOSE history.
      #
      # @returns [String | Nil] the session id absorbed, or nil if it was
      #   already held or the payload was not a room key.
      def absorb(payload)
        type = payload["type"]

        if type == ROOM_KEY || type == FORWARDED_ROOM_KEY
          store_room_key(payload["content"] || {}, forwarded: type == FORWARDED_ROOM_KEY)
        end
      end

      # Import a session recovered from server-side key backup.
      #
      # A DIFFERENT KEY FORMAT from a live m.room_key, which is the whole reason
      # this is its own method: a backup blob carries an unsigned, version-1
      # ExportedSessionKey, and InboundGroupSession.new rejects it outright --
      # only .import accepts one. A session built this way carries no signature,
      # so it cannot be attributed to the device that originally created it;
      # `signing_key` is what the blob claims, kept for whatever wants to decide
      # how much to trust it.
      #
      # @returns [String | Nil] the session id, or nil if already held.
      def import_session(room_id:, session_id:, session_key:, sender_key: nil, signing_key: nil)
        if @e2ee.nil?
          raise MissingPrimitivesError, "no e2ee factory was supplied, so no session can be imported"
        end

        if @group_sessions.key?(session_id)
          nil
        else
          put_group_session(
            session_id,
            @e2ee::InboundGroupSession.import(session_key),
            room_id,
            sender_key:  sender_key,
            signing_key: signing_key,
          )
        end
      end

      # Add a room key we already hold a session object for.
      def add_group_session(session, room_id:)
        put_group_session(session.session_id, session, room_id)
      end

      def knows_session?(session_id) = @group_sessions.key?(session_id)

      # Every room key held, as session_id => room_id.
      def room_keys
        @group_sessions.transform_values { |entry| entry[:room_id] }
      end

      def olm_sessions_with(sender_key) = Array(@olm_sessions[sender_key])

      # ── What the caller must persist ────────────────────────────────────────

      # Every piece of state this store advanced since the last #flush_changes!.
      #
      # THE CALLER MUST WRITE THESE. Olm and Megolm both ratchet, so a session
      # that decrypted a message and was not saved will fail on the next one --
      # permanently, because the peer has moved on and we have not. The account
      # matters for the same reason: a prekey message consumes a one-time key.
      def changes
        {
          account:        @account_changed ? @account : nil,
          olm_sessions:   @changed_olm_sessions.uniq,
          group_sessions: @changed_group_sessions.uniq,
          outbound_rooms: @changed_outbound_rooms.uniq,
        }
      end

      # Everything that changed, PICKLED AND READY TO WRITE.
      #
      # #changes names what moved; this hands over the bytes. The distinction
      # matters because #changes alone was not enough to act on: it reports
      # session ids, and an id cannot be pickled -- only the object can, and
      # only the store holds those.
      #
      # Returns plain data. Where it goes, in what table, under what column, on
      # what schedule, is the application's business entirely.
      #
      # @parameter pickle_key [PickleKey] see that class for why losing it loses
      #   everything that was ever encrypted to this device.
      def export(pickle_key)
        key = pickle_key.to_s

        {
          account:           @account_changed ? @account.pickle(key) : nil,
          olm_sessions:      export_olm_sessions(key),
          group_sessions:    export_group_sessions(key),
          outbound_sessions: export_outbound_sessions(key),
        }
      end


      def changed?
        @account_changed || @changed_olm_sessions.any? ||
          @changed_group_sessions.any? || @changed_outbound_rooms.any?
      end

      def flush_changes!
        @changed_olm_sessions = []
        @changed_group_sessions = []
        @changed_outbound_rooms = []
        @account_changed = false
        self
      end

      private

        # Looked up by id rather than kept as a list of objects, so a session
        # that ratcheted several times in one batch is pickled once, at its
        # final position.
        def export_olm_sessions(key)
          @changed_olm_sessions.uniq.filter_map do |session_id|
            found = find_olm_session(session_id)

            if found
              {session_id: session_id, sender_key: found.first, pickle: found.last.pickle(key)}
            end
          end
        end

        # No index from session id to peer, because the store is keyed the way
        # the protocol is: Olm sessions are found BY PEER when decrypting. The
        # scan costs nothing at the size this ever reaches -- a handful of
        # sessions changed in one batch.
        def find_olm_session(session_id)
          pair = nil

          @olm_sessions.each do |sender_key, sessions|
            session = sessions.find { |candidate| candidate.session_id == session_id }

            if session
              pair = [sender_key, session]
              break
            end
          end

          pair
        end

        def export_group_sessions(key)
          @changed_group_sessions.uniq.filter_map do |session_id|
            entry = @group_sessions[session_id]

            if entry
              {
                session_id:  session_id,
                room_id:     entry[:room_id],
                sender_key:  entry[:sender_key],
                signing_key: entry[:signing_key],
                pickle:      entry[:session].pickle(key),
              }
            end
          end
        end

        def export_outbound_sessions(key)
          @changed_outbound_rooms.uniq.filter_map do |room_id|
            entry = @outbound_sessions[room_id]

            if entry
              {
                room_id:       room_id,
                session_id:    entry[:session].session_id,
                message_count: entry[:message_count],
                started_at:    entry[:started_at],
                shared_with:   entry[:shared_with],
                pickle:        entry[:session].pickle(key),
              }
            end
          end
        end


        # The session id is the key, and it comes from ONE place per path: the
        # payload when absorbing a received key, the session object when the
        # caller supplies one directly. The two agree in practice; keying off
        # whichever was to hand would hide it when they did not.
        # The spec: a client "should remember the megolm `message_index` ... of
        # each event they decrypt for each session" and treat a repeat as
        # invalid -- UNLESS the event_id and origin_server_ts also match, which
        # is the legitimate case of decrypting the same event twice.
        #
        # Without this, anyone who can place an event in the room can replay an
        # old message under a fresh event id and have it accepted as new.
        def check_message_index(message)
          index = message.message_index

          if index.nil?
            nil
          else
            seen = @message_indexes[message.session_id] ||= {}
            previous = seen[index]
            current = [message.event_id, message.origin_server_ts]

            if previous.nil?
              seen[index] = current
            elsif previous != current
              raise ReplayError,
                "session #{message.session_id} index #{index} already decrypted as " \
                "#{previous.first.inspect}; this event claims #{message.event_id.inspect}"
            end
          end
        end

        # The same guard for Olm: a to-device ciphertext delivered twice is a
        # replay, and an Olm session will happily decrypt a prekey message again.
        def check_olm_replay(sender_key, info)
          digest = Digest::SHA256.hexdigest("#{sender_key}|#{info['type']}|#{info['body']}")

          if @olm_hashes.key?(digest)
            raise ReplayError, "olm message from #{sender_key} was already decrypted"
          end

          @olm_hashes[digest] = now_ms
        end

        def expired?(entry, rotation)
          messages = rotation[:rotation_period_msgs] || rotation["rotation_period_msgs"] ||
            DEFAULT_ROTATION_MESSAGES
          period = rotation[:rotation_period_ms] || rotation["rotation_period_ms"] ||
            DEFAULT_ROTATION_MS

          entry[:message_count] >= messages || (now_ms - entry[:started_at]) >= period
        end

        def open_outbound_session(identity_key, one_time_key)
          if one_time_key.nil?
            nil
          else
            if one_time_key.is_a?(Hash)
              key = (one_time_key["key"] || one_time_key[:key])
            else
              key = one_time_key
            end
            session = @account.create_outbound_session(identity_key, key)
            @account_changed = true
            (@olm_sessions[identity_key] ||= []).unshift(session)
            session
          end
        end

        def now_ms = (Time.now.to_f * 1000).to_i

        def put_group_session(session_id, session, room_id, sender_key: nil, signing_key: nil)
          if @group_sessions.key?(session_id)
            nil
          else
            @group_sessions[session_id] = {
              session:     session,
              room_id:     room_id,
              sender_key:  sender_key,
              signing_key: signing_key,
            }
            @changed_group_sessions << session_id
            session_id
          end
        end

        def decrypt_megolm(message)
          entry = @group_sessions[message.session_id]

          if entry.nil?
            nil
          else
            # A key is issued FOR A ROOM. Using one against a message in another
            # room would let a sender have a message attributed to a room they
            # hold no key for.
            if message.room_id && entry[:room_id] && message.room_id != entry[:room_id]
              raise RoomMismatchError,
                "session #{message.session_id} belongs to #{entry[:room_id]}, " \
                "message claims #{message.room_id}"
            end

            message.decrypt!(entry[:session])
            @changed_group_sessions << message.session_id
            check_message_index(message)

            # The payload carries its own room_id, and a sender whose payload
            # disagrees with the envelope is attempting the same substitution
            # from the inside.
            if message.payload_room_id && message.room_id &&
                message.payload_room_id != message.room_id
              raise RoomMismatchError,
                "payload claims #{message.payload_room_id}, envelope says #{message.room_id}"
            end

            message
          end
        end

        def decrypt_olm(message)
          info = message.ciphertext_for(identity_key)

          if info.nil?
            nil
          else
            check_olm_replay(message.sender_key, info)
            payload = with_known_session(message) || with_new_session(message, info)

            if payload
              absorb(payload)
              message
            end
          end
        end

        # Every session we already have with this peer, newest first. Several can
        # exist when both sides opened one at the same time, and only one holds
        # the ratchet state that reads this message.
        def with_known_session(message)
          decrypted = nil

          olm_sessions_with(message.sender_key).each do |session|
            decrypted = try_session(message, session)

            if decrypted
              @changed_olm_sessions << session.session_id
              break
            end
          end

          decrypted
        end

        def try_session(message, session)
          message.decrypt!(session, identity_key: identity_key)
        rescue Protocol::Matrix::Errors::DecryptionError
          nil
        end

        # A prekey message carries enough to open a NEW inbound session, and
        # doing so CONSUMES one of our one-time keys -- which is why the account
        # is marked changed even when the decryption then fails.
        def with_new_session(message, info)
          if info["type"] == Protocol::Matrix::EncryptedMessage::PREKEY
            session = open_inbound_session(message, info)
            @account_changed = true

            (@olm_sessions[message.sender_key] ||= []).unshift(session)
            @changed_olm_sessions << session.session_id

            # Deliberately OUTSIDE the rescue below: a payload that decrypts to
            # nonsense is a malformed message, not a failure to establish a
            # session, and conflating them sends a reader looking in the wrong
            # place.
            try_session(message, session)
          end
        end

        # Consumes one of our one-time keys, whether or not what follows works --
        # which is why the account is marked changed even on a later failure.
        def open_inbound_session(message, info)
          session, _plaintext = @account.create_inbound_session(message.sender_key, info["body"])
          session
        rescue StandardError => e
          raise Error, "could not open an inbound session from #{message.sender_key}: #{e.message}"
        end

        def store_room_key(content, forwarded:)
          if content["algorithm"] != MEGOLM
            nil
          else
            session_id = content["session_id"]

            if session_id.nil? || @group_sessions.key?(session_id)
              # Checked BEFORE building: constructing the session would be
              # wasted work, and for a forwarded key it would also be the wrong
              # answer -- the one already held is further back in the ratchet.
              nil
            else
              put_group_session(
                session_id,
                build_group_session(content, forwarded: forwarded),
                content["room_id"],
                sender_key:  content["sender_key"],
                signing_key: (content["sender_claimed_keys"] || {})["ed25519"],
              )
            end
          end
        end

        # A direct room key is a signed, version-2 SessionKey; a FORWARDED one is
        # an unsigned, version-1 ExportedSessionKey, which .new rejects outright.
        # Different constructors, and the distinction is not cosmetic: a session
        # built from a forwarded key carries no signature and so cannot be
        # attributed to the device that originally created it.
        def build_group_session(content, forwarded:)
          if @e2ee.nil?
            raise MissingPrimitivesError,
              "no e2ee factory was supplied, so a received room key cannot be built"
          end

          if forwarded
            @e2ee::InboundGroupSession.import(content["session_key"])
          else
            @e2ee::InboundGroupSession.new(content["session_key"])
          end
        end
    end
  end
end

__END__
  describe "Async::Matrix::DeviceStore" do
    # Fake primitives. The store names no native extension -- the account and
    # the factory are injected -- so the whole class is driveable with three
    # plain objects and no cryptography.
    def fake_account(identity: "ourcurve", fingerprint: "oured")
      account = Object.new
      opened = []
      account.define_singleton_method(:curve25519_key) { identity }
      account.define_singleton_method(:pickle) { |_key| "account-pickle" }
      account.define_singleton_method(:ed25519_key) { fingerprint }
      account.define_singleton_method(:opened) { opened }
      published = 0
      account.define_singleton_method(:sign) { |_message| "SIGNED" }
      account.define_singleton_method(:published) { published }
      account.define_singleton_method(:max_number_of_one_time_keys) { 100 }
      account.define_singleton_method(:generate_one_time_keys) { |_count| nil }
      account.define_singleton_method(:one_time_keys) { {"k1" => "otk1", "k2" => "otk2"} }
      account.define_singleton_method(:generate_fallback_key) { nil }
      account.define_singleton_method(:fallback_key) { {"fb1" => "fbkey"} }
      account.define_singleton_method(:mark_keys_as_published) { published += 1 }
      account.define_singleton_method(:create_outbound_session) do |identity_key, one_time_key|
        session = Object.new
        session.define_singleton_method(:session_id) { "outbound-olm" }
        session.define_singleton_method(:pickle) { |_key| "session-pickle" }
        session.define_singleton_method(:encrypt) { |plaintext| [0, "prekey:#{plaintext.length}"] }
        session
      end
      account.define_singleton_method(:create_inbound_session) do |sender_key, body|
        opened << [sender_key, body]
        payload = JSON.generate({
          "type" => "m.dummy", "content" => {},
          "sender" => "@bob:example.org", "recipient" => "@bot:example.org",
          "recipient_keys" => {"ed25519" => "oured"}, "keys" => {"ed25519" => "theired"},
        })
        session = Object.new
        session.define_singleton_method(:session_id) { "new-olm-session" }
        session.define_singleton_method(:pickle) { |_key| "session-pickle" }
        session.define_singleton_method(:decrypt) { |_type, _body| payload }
        [session, payload]
      end
      account
    end

    def fake_olm_session(id, plaintext)
      session = Object.new
      session.define_singleton_method(:session_id) { id }
      session.define_singleton_method(:pickle) { |_key| "session-pickle" }
      session.define_singleton_method(:decrypt) do |_type, _body|
        plaintext || raise(RuntimeError, "BAD_MESSAGE_MAC")
      end
      session
    end

    def olm_encrypting_session
      session = Object.new
      session.define_singleton_method(:session_id) { "existing-olm" }
      session.define_singleton_method(:pickle) { |_key| "session-pickle" }
      session.define_singleton_method(:encrypt) { |plaintext| [1, "msg:#{plaintext.length}"] }
      session
    end

    # Reports a new message index each time, as a real session does.
    def counting_group_session
      index = -1
      session = Object.new
      session.define_singleton_method(:session_id) { "s" }
      session.define_singleton_method(:pickle) { |_key| "inboundgroupsession-pickle" }
      session.define_singleton_method(:decrypt) do |_ciphertext|
        index += 1
        [JSON.generate({"type" => "m.room.message", "content" => {}, "room_id" => "!room:example.org"}), index]
      end
      session
    end

    def fake_group_session(id, plaintext, index = 0)
      session = Object.new
      session.define_singleton_method(:session_id) { id }
      session.define_singleton_method(:pickle) { |_key| "inboundgroupsession-pickle" }
      session.define_singleton_method(:decrypt) { |_ciphertext| [plaintext, index] }
      session
    end

    # Stands in for Async::Matrix::E2EE: all the store asks of it is
    # InboundGroupSession.new / .import.
    def fake_e2ee
      built = []
      # A payload the reader accepts: anything without type and content is
      # refused, and rightly.
      valid_payload = JSON.generate({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "from backup"},
        "room_id" => "!room:example.org",
      })
      factory = Module.new
      klass = Class.new do
        define_singleton_method(:built) { built }
        define_singleton_method(:new) do |session_key|
          built << [:new, session_key]
          session = Object.new
          session.define_singleton_method(:session_id) { "session-from-#{session_key}" }
          session.define_singleton_method(:pickle) { |_key| "inboundgroupsession-pickle" }
          session.define_singleton_method(:decrypt) { |_c| [valid_payload, 0] }
          session
        end
        define_singleton_method(:import) do |exported|
          built << [:import, exported]
          session = Object.new
          session.define_singleton_method(:session_id) { "session-from-#{exported}" }
          session.define_singleton_method(:pickle) { |_key| "inboundgroupsession-pickle" }
          session.define_singleton_method(:decrypt) { |_c| [valid_payload, 0] }
          session
        end
      end
      factory.const_set(:InboundGroupSession, klass)

      group = Class.new do
        define_singleton_method(:new) do
          counter = 0
          session = Object.new
          session.define_singleton_method(:session_id) { "outbound1" }
          session.define_singleton_method(:session_key) { "AgAAAAoutbound" }
          session.define_singleton_method(:pickle) { |_key| "groupsession-pickle" }
          session.define_singleton_method(:encrypt) do |plaintext|
            counter += 1
            "cipher#{counter}:#{plaintext.length}"
          end
          session
        end
      end
      factory.const_set(:GroupSession, group)
      factory
    end

    def build_store(**options)
      Async::Matrix::DeviceStore.new(
        **{
          user_id: "@bot:example.org",
          device_id: "ABCDEFGHIJ",
          account: fake_account,
        }.merge(options),
      )
    end

    def megolm_message(session_id: "session1", room_id: "!room:example.org")
      Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "event_id" => "$evt1",
        "room_id" => room_id,
        "sender" => "@alice:example.org",
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "ciphertext" => "AwgAEnAC",
          "session_id" => session_id,
        },
      })
    end

    def olm_message(type: 0, sender_key: "theircurve", recipient: "ourcurve")
      Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "sender" => "@bob:example.org",
        "content" => {
          "algorithm" => "m.olm.v1.curve25519-aes-sha2",
          "sender_key" => sender_key,
          "ciphertext" => {recipient => {"type" => type, "body" => "olmbody"}},
        },
      })
    end

    def room_key_payload(session_id: "shared1", room_id: "!room:example.org", type: "m.room_key")
      JSON.generate({
        "type" => type,
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "room_id" => room_id,
          "session_id" => session_id,
          "session_key" => "AgAAAAsession",
        },
        "sender" => "@bob:example.org",
        "recipient" => "@bot:example.org",
        "recipient_keys" => {"ed25519" => "oured"},
        "keys" => {"ed25519" => "theired"},
      })
    end

    def megolm_payload(room_id = "!room:example.org")
      JSON.generate({
        "type" => "m.room.message",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
        "room_id" => room_id,
      })
    end

    # ── Identity ──────────────────────────────────────────────────────────────

    it "exposes the device's own keys" do
      store = build_store

      store.identity_key.should == "ourcurve"
      store.fingerprint.should == "oured"
      store.user_id.should == "@bot:example.org"
      store.device_id.should == "ABCDEFGHIJ"
    end

    # ── Reading megolm ────────────────────────────────────────────────────────

    it "decrypts a room message with the key it holds" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload), room_id: "!room:example.org"},
        },
      )
      message = store.decrypt(megolm_message)

      message.decrypted?.should == true
      message.type.should == "m.room.message"
      message.content.should == {"msgtype" => "m.text", "body" => "hello"}
    end

    # A key for any room: the store holds them all, so nothing about the room
    # has to be arranged in advance.
    it "decrypts messages from several rooms" do
      store = build_store(
        group_sessions: {
          "s-a" => {session: fake_group_session("s-a", megolm_payload("!a:example.org")), room_id: "!a:example.org"},
          "s-b" => {session: fake_group_session("s-b", megolm_payload("!b:example.org")), room_id: "!b:example.org"},
        },
      )

      store.decrypt(megolm_message(session_id: "s-a", room_id: "!a:example.org")).decrypted?.should == true
      store.decrypt(megolm_message(session_id: "s-b", room_id: "!b:example.org")).decrypted?.should == true
      store.room_keys.length.should == 2
    end

    # NOT AN ERROR. The key may arrive later in this batch, in a later one, or
    # from backup; raising would make the commonest state exceptional.
    it "answers nil for a message it holds no key for" do
      store = build_store

      store.decrypt(megolm_message).should.be.nil
    end

    # A key is issued FOR A ROOM. Honouring it elsewhere would let a sender have
    # a message attributed to a room they hold no key for.
    it "refuses a session issued for a different room" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload), room_id: "!elsewhere:example.org"},
        },
      )

      lambda {
        store.decrypt(megolm_message(room_id: "!room:example.org"))
      }.should.raise(Async::Matrix::DeviceStore::RoomMismatchError)
    end

    # The same substitution attempted from inside the ciphertext.
    it "refuses a payload whose room disagrees with the envelope" do
      store = build_store(
        group_sessions: {
          "session1" => {
            session: fake_group_session("session1", megolm_payload("!other:example.org")),
            room_id: "!room:example.org",
          },
        },
      )

      lambda {
        store.decrypt(megolm_message(room_id: "!room:example.org"))
      }.should.raise(Async::Matrix::DeviceStore::RoomMismatchError)
    end

    # ── Reading olm, and absorbing what it carries ────────────────────────────

    it "decrypts a to-device message with a session it already has" do
      store = build_store(
        e2ee: fake_e2ee,
        olm_sessions: {"theircurve" => [fake_olm_session("olm1", room_key_payload)]},
      )
      message = store.decrypt(olm_message(type: 1))

      message.decrypted?.should == true
      message.type.should == "m.room_key"
    end

    # THE POINT OF THE CLASS: reading a to-device message leaves the store able
    # to read the room.
    it "absorbs a room key as it reads it" do
      store = build_store(
        e2ee: fake_e2ee,
        olm_sessions: {"theircurve" => [fake_olm_session("olm1", room_key_payload(session_id: "shared1"))]},
      )

      store.knows_session?("shared1").should == false
      store.decrypt(olm_message(type: 1))
      store.knows_session?("shared1").should == true
      store.room_keys["shared1"].should == "!room:example.org"
    end

    it "tries every session it has with a peer, newest first" do
      store = build_store(
        e2ee: fake_e2ee,
        olm_sessions: {
          "theircurve" => [
            fake_olm_session("stale", nil),
            fake_olm_session("good", room_key_payload),
          ],
        },
      )

      store.decrypt(olm_message(type: 1)).decrypted?.should == true
      store.changes[:olm_sessions].should == ["good"]
    end

    # A prekey message is the only kind that can open a new session, and doing
    # so consumes one of our one-time keys.
    it "opens a new inbound session from a prekey message" do
      account = fake_account
      store = build_store(account: account, e2ee: fake_e2ee)

      store.decrypt(olm_message(type: 0))

      account.opened.should == [["theircurve", "olmbody"]]
      store.olm_sessions_with("theircurve").length.should == 1
      store.changes[:account].should == account
    end

    it "does not open a session for an ordinary olm message" do
      account = fake_account
      store = build_store(account: account)

      store.decrypt(olm_message(type: 1)).should.be.nil
      account.opened.should == []
    end

    it "ignores a to-device message addressed to another device" do
      store = build_store

      store.decrypt(olm_message(recipient: "someone-elses-key")).should.be.nil
    end

    # ── Absorbing room keys directly ──────────────────────────────────────────

    it "builds a direct room key with .new and a forwarded one with .import" do
      factory = fake_e2ee
      store = build_store(e2ee: factory)

      store.absorb(JSON.parse(room_key_payload(session_id: "a")))
      store.absorb(JSON.parse(room_key_payload(session_id: "b", type: "m.forwarded_room_key")))

      factory::InboundGroupSession.built.map(&:first).should == [:new, :import]
    end

    # The session already held is the one further back in the ratchet, so
    # replacing it would lose history.
    it "keeps the key it already holds rather than replacing it" do
      factory = fake_e2ee
      store = build_store(e2ee: factory)

      store.absorb(JSON.parse(room_key_payload)).should == "shared1"
      store.absorb(JSON.parse(room_key_payload)).should.be.nil
      factory::InboundGroupSession.built.length.should == 1
    end

    it "ignores a payload that is not a room key" do
      store = build_store(e2ee: fake_e2ee)

      store.absorb({"type" => "m.room.message", "content" => {}}).should.be.nil
    end

    it "ignores a room key for an algorithm it does not implement" do
      store = build_store(e2ee: fake_e2ee)
      payload = JSON.parse(room_key_payload)
      payload["content"]["algorithm"] = "m.megolm.v2.made-up"

      store.absorb(payload).should.be.nil
    end

    it "reports plainly when no factory was supplied" do
      store = build_store

      lambda {
        store.absorb(JSON.parse(room_key_payload))
      }.should.raise(Async::Matrix::DeviceStore::MissingPrimitivesError)
    end

    # ── What the caller must persist ──────────────────────────────────────────

    # Both algorithms ratchet, so a session that read a message and was not
    # saved fails on the next one -- permanently.
    it "reports the sessions that ratcheted" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload), room_id: "!room:example.org"},
        },
      )

      store.changed?.should == false
      store.decrypt(megolm_message)
      store.changed?.should == true
      store.changes[:group_sessions].should == ["session1"]
    end

    it "clears what it reported once the caller has written it" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload), room_id: "!room:example.org"},
        },
      )
      store.decrypt(megolm_message)
      store.flush_changes!

      store.changed?.should == false
      store.changes[:group_sessions].should == []
    end

    it "reports a new room key as something to persist" do
      store = build_store(e2ee: fake_e2ee)
      store.absorb(JSON.parse(room_key_payload))

      store.changes[:group_sessions].should == ["shared1"]
    end

    it "does not report the account until a one-time key is consumed" do
      store = build_store(
        olm_sessions: {"theircurve" => [fake_olm_session("olm1", room_key_payload)]},
        e2ee: fake_e2ee,
      )
      store.decrypt(olm_message(type: 1))

      store.changes[:account].should.be.nil
    end

    # ── Unknown algorithms ────────────────────────────────────────────────────

    it "refuses an algorithm it does not implement" do
      store = build_store
      message = Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "content" => {"algorithm" => "m.made.up", "ciphertext" => "x"},
      })

      lambda {
        store.decrypt(message)
      }.should.raise(Protocol::Matrix::Errors::UnsupportedAlgorithmError)
    end
    # ── Publishing ────────────────────────────────────────────────────────────

    it "builds its own signed device keys" do
      store = build_store
      keys = store.device_keys

      keys["user_id"].should == "@bot:example.org"
      keys["device_id"].should == "ABCDEFGHIJ"
      keys["keys"].should == {
        "curve25519:ABCDEFGHIJ" => "ourcurve",
        "ed25519:ABCDEFGHIJ" => "oured",
      }
      keys["signatures"]["@bot:example.org"]["ed25519:ABCDEFGHIJ"].should == "SIGNED"
    end

    it "generates and signs one-time keys" do
      store = build_store
      keys = store.generate_one_time_keys(2)

      keys.keys.sort.should == ["signed_curve25519:k1", "signed_curve25519:k2"]
      keys["signed_curve25519:k1"]["key"].should == "otk1"
      keys["signed_curve25519:k1"]["signatures"].should ==
        {"@bot:example.org" => {"ed25519:ABCDEFGHIJ" => "SIGNED"}}
    end

    it "generates a fallback key, marked as one" do
      store = build_store

      store.generate_fallback_key["signed_curve25519:fb1"]["fallback"].should == true
    end

    # Generating consumes account state, so the caller has to save it.
    it "reports the account as changed after generating keys" do
      store = build_store
      store.generate_one_time_keys(1)

      store.changes[:account].should.not.be.nil
    end

    # The account forgets a key once marked published, so marking before the
    # upload succeeds discards keys the server never got.
    it "does not mark keys published until told to" do
      account = fake_account
      store = build_store(account: account)
      store.generate_one_time_keys(1)

      account.published.should == 0

      store.mark_keys_published!
      account.published.should == 1
    end

    it "asks for half the maximum, as the spec suggests" do
      build_store.default_one_time_key_count.should == 50
    end

    # Compared against what the SERVER says it holds: keys are consumed by peers
    # claiming them, which we never see.
    it "tops up based on the server's count" do
      store = build_store

      store.needs_one_time_keys?(0).should == true
      store.needs_one_time_keys?(49).should == true
      store.needs_one_time_keys?(50).should == false
    end
    # ── Writing: megolm ───────────────────────────────────────────────────────

    it "encrypts a room event and says which session it used" do
      store = build_store(e2ee: fake_e2ee)
      content, session_id, shared = store.encrypt(
        room_id: "!room:example.org", type: "m.room.message", content: {"body" => "hi"},
      )

      content["algorithm"].should == "m.megolm.v1.aes-sha2"
      content["session_id"].should == "outbound1"
      content["sender_key"].should == "ourcurve"
      content["device_id"].should == "ABCDEFGHIJ"
      session_id.should == "outbound1"
      shared.should == {}
    end

    it "reuses the room's session across messages" do
      store = build_store(e2ee: fake_e2ee)
      first = store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      second = store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})

      first[1].should == second[1]
      first[0]["ciphertext"].should.not == second[0]["ciphertext"]
    end

    # Spec defaults for m.room.encryption.
    it "rotates after the message limit" do
      store = build_store(e2ee: fake_e2ee)
      100.times { store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {}) }
      entry = store.outbound_session("!r:example.org")

      entry[:message_count].should == 0
    end

    it "honours the room's own rotation policy" do
      store = build_store(e2ee: fake_e2ee)
      rotation = {"rotation_period_msgs" => 2}
      3.times { store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {}, rotation: rotation) }

      store.outbound_session("!r:example.org", rotation: rotation)[:message_count].should == 1
    end

    # Whoever left still holds the current key, so every later message would be
    # readable by them. No timer does this in time.
    it "starts a new session when told to rotate" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      store.record_shared!("!r:example.org", {"@ada:example.org" => ["DEV1"]})

      store.rotate!("!r:example.org")

      store.shared_with?("!r:example.org", "@ada:example.org", "DEV1").should == false
      store.outbound_session("!r:example.org")[:message_count].should == 0
    end

    it "tracks who already holds the room's key" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})

      store.shared_with?("!r:example.org", "@ada:example.org", "DEV1").should == false
      store.record_shared!("!r:example.org", {"@ada:example.org" => ["DEV1", "DEV2"]})
      store.shared_with?("!r:example.org", "@ada:example.org", "DEV1").should == true
      store.record_shared!("!r:example.org", {"@ada:example.org" => ["DEV3"]})
      store.shared_with?("!r:example.org", "@ada:example.org", "DEV1").should == true
      store.shared_with?("!r:example.org", "@ada:example.org", "DEV3").should == true
    end

    # An outbound session cannot decrypt, so without keeping the inbound twin we
    # could not read our own messages back.
    it "keeps its own room key when handing it out" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      payload = store.room_key_payload("!r:example.org")

      payload["type"].should == "m.room_key"
      payload["content"]["session_id"].should == "outbound1"
      payload["content"]["room_id"].should == "!r:example.org"
      store.room_keys.values.should == ["!r:example.org"]
    end

    it "has no room key payload for a room it never sent to" do
      build_store(e2ee: fake_e2ee).room_key_payload("!never:example.org").should.be.nil
    end

    it "refuses to start a session with no factory" do
      lambda {
        build_store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      }.should.raise(Async::Matrix::DeviceStore::MissingPrimitivesError)
    end

    # ── Writing: olm ──────────────────────────────────────────────────────────

    it "wraps a payload for a device it already has a session with" do
      store = build_store(olm_sessions: {"theircurve" => [olm_encrypting_session]})
      content = store.encrypt_to_device(
        {"type" => "m.room_key", "content" => {"a" => 1}},
        recipient: "@bob:example.org",
        recipient_identity_key: "theircurve",
        recipient_key: "theired",
      )

      content["algorithm"].should == "m.olm.v1.curve25519-aes-sha2"
      content["sender_key"].should == "ourcurve"
      content["ciphertext"]["theircurve"]["type"].should == 1
    end

    it "opens a session from a claimed key when it has none" do
      store = build_store
      content = store.encrypt_to_device(
        {"type" => "m.room_key", "content" => {}},
        recipient: "@bob:example.org",
        recipient_identity_key: "theircurve",
        recipient_key: "theired",
        one_time_key: {"key" => "theirotk"},
      )

      content["ciphertext"]["theircurve"]["type"].should == 0
      store.olm_sessions_with("theircurve").length.should == 1
    end

    # Unreachable rather than guessable: with no session and no claimed key
    # there is nothing to encrypt to.
    it "answers nil for a device it cannot reach" do
      build_store.encrypt_to_device(
        {"type" => "m.room_key", "content" => {}},
        recipient: "@bob:example.org",
        recipient_identity_key: "theircurve",
        recipient_key: "theired",
      ).should.be.nil
    end

    # ── Replay protection ─────────────────────────────────────────────────────

    # The spec: remember the message_index per session and treat a repeat as
    # invalid, unless event_id and origin_server_ts also match.
    it "accepts the same event decrypted twice" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload, 5), room_id: "!room:example.org"},
        },
      )

      store.decrypt(megolm_message).should.not.be.nil
      store.decrypt(megolm_message).should.not.be.nil
    end

    # A message replayed under a fresh event id would otherwise be accepted as
    # new.
    it "refuses a reused message index under a different event id" do
      store = build_store(
        group_sessions: {
          "session1" => {session: fake_group_session("session1", megolm_payload, 5), room_id: "!room:example.org"},
        },
      )
      store.decrypt(megolm_message)

      replayed = Protocol::Matrix::EncryptedMessage.new({
        "type" => "m.room.encrypted",
        "event_id" => "$different",
        "room_id" => "!room:example.org",
        "sender" => "@alice:example.org",
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "ciphertext" => "AwgAEnAC",
          "session_id" => "session1",
        },
      })

      lambda { store.decrypt(replayed) }.should.raise(Async::Matrix::DeviceStore::ReplayError)
    end

    it "allows different indexes in the same session" do
      store = build_store(
        group_sessions: {
          "s" => {session: counting_group_session, room_id: "!room:example.org"},
        },
      )

      store.decrypt(megolm_message(session_id: "s")).should.not.be.nil
      store.decrypt(
        Protocol::Matrix::EncryptedMessage.new({
          "type" => "m.room.encrypted", "event_id" => "$two", "room_id" => "!room:example.org",
          "sender" => "@alice:example.org",
          "content" => {"algorithm" => "m.megolm.v1.aes-sha2", "ciphertext" => "c", "session_id" => "s"},
        }),
      ).should.not.be.nil
    end

    # An Olm session will decrypt a prekey message again quite happily.
    it "refuses the same olm ciphertext twice" do
      store = build_store(
        e2ee: fake_e2ee,
        olm_sessions: {"theircurve" => [fake_olm_session("olm1", room_key_payload)]},
      )

      store.decrypt(olm_message(type: 1)).should.not.be.nil
      lambda { store.decrypt(olm_message(type: 1)) }.should.raise(Async::Matrix::DeviceStore::ReplayError)
    end

    it "reports an outbound room as needing persistence" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})

      store.changes[:outbound_rooms].should == ["!r:example.org"]
      store.flush_changes!
      store.changes[:outbound_rooms].should == []
    end
    # ── Importing from backup ─────────────────────────────────────────────────

    # The format is the point: a backup blob carries an unsigned, version-1
    # ExportedSessionKey, which .new rejects -- only .import takes one.
    it "imports a session recovered from backup" do
      factory = fake_e2ee
      store = build_store(e2ee: factory)

      store.import_session(
        room_id: "!old:example.org",
        session_id: "backed-up-1",
        session_key: "AgAAAADxexported",
        sender_key: "theircurve",
        signing_key: "theired",
      ).should == "backed-up-1"

      store.knows_session?("backed-up-1").should == true
      store.room_keys["backed-up-1"].should == "!old:example.org"
      factory::InboundGroupSession.built.should == [[:import, "AgAAAADxexported"]]
    end

    # The live key we already hold is further back in the ratchet, so a backup
    # copy must not replace it.
    it "keeps a session it already holds" do
      store = build_store(e2ee: fake_e2ee)
      store.import_session(room_id: "!r:example.org", session_id: "s1", session_key: "k")

      store.import_session(room_id: "!r:example.org", session_id: "s1", session_key: "k").should.be.nil
    end

    it "reports an imported session as something to persist" do
      store = build_store(e2ee: fake_e2ee)
      store.import_session(room_id: "!r:example.org", session_id: "s1", session_key: "k")

      store.changes[:group_sessions].should == ["s1"]
    end

    it "says plainly when it has no factory to import with" do
      lambda {
        build_store.import_session(room_id: "!r:example.org", session_id: "s1", session_key: "k")
      }.should.raise(Async::Matrix::DeviceStore::MissingPrimitivesError)
    end

    # Decrypting works the same whether the key arrived live or from backup.
    it "decrypts with an imported session" do
      factory = fake_e2ee
      store = build_store(e2ee: factory)
      store.import_session(
        room_id: "!room:example.org", session_id: "session1", session_key: "exported",
      )

      store.decrypt(megolm_message).should.not.be.nil
    end
    # ── Exporting what to persist ─────────────────────────────────────────────

    def pickle_key = Async::Matrix::E2EE::PickleKey.derive("a test secret")

    # #changes names what moved; #export hands over the bytes. The difference is
    # the point: an id cannot be pickled, and only the store holds the objects.
    it "exports the pickled account once a one-time key is consumed" do
      store = build_store(e2ee: fake_e2ee)
      store.decrypt(olm_message(type: 0))

      store.export(pickle_key)[:account].should == "account-pickle"
    end

    it "exports nothing for an untouched store" do
      store = build_store(e2ee: fake_e2ee)
      exported = store.export(pickle_key)

      exported[:account].should.be.nil
      exported[:olm_sessions].should == []
      exported[:group_sessions].should == []
      exported[:outbound_sessions].should == []
    end

    # An Olm session is found BY PEER when decrypting, so there is no index from
    # session id back to peer -- export has to look it up, and it must find it.
    it "exports a ratcheted olm session with the peer it belongs to" do
      store = build_store(
        e2ee: fake_e2ee,
        olm_sessions: {"theircurve" => [fake_olm_session("olm1", room_key_payload)]},
      )
      store.decrypt(olm_message(type: 1))
      rows = store.export(pickle_key)[:olm_sessions]

      rows.length.should == 1
      rows.first[:session_id].should == "olm1"
      rows.first[:sender_key].should == "theircurve"
      rows.first[:pickle].should == "session-pickle"
    end

    it "exports a received room key with what it claimed about its sender" do
      store = build_store(e2ee: fake_e2ee)
      store.absorb(JSON.parse(room_key_payload))
      row = store.export(pickle_key)[:group_sessions].first

      row[:session_id].should == "shared1"
      row[:room_id].should == "!room:example.org"
      row[:pickle].should == "inboundgroupsession-pickle"
    end

    it "exports an outbound session with its rotation bookkeeping" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      store.record_shared!("!r:example.org", {"@ada:example.org" => ["DEV1"]})
      row = store.export(pickle_key)[:outbound_sessions].first

      row[:room_id].should == "!r:example.org"
      row[:session_id].should == "outbound1"
      row[:message_count].should == 1
      row[:shared_with].should == {"@ada:example.org" => ["DEV1"]}
      row[:pickle].should == "groupsession-pickle"
      row[:started_at].should.not.be.nil
    end

    # A session that ratchets several times in one batch is pickled once, at its
    # final position -- not once per message.
    it "exports a repeatedly ratcheted session once" do
      store = build_store(e2ee: fake_e2ee)
      3.times { store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {}) }
      rows = store.export(pickle_key)[:outbound_sessions]

      rows.length.should == 1
      rows.first[:message_count].should == 3
    end

    it "exports nothing again once the caller has flushed" do
      store = build_store(e2ee: fake_e2ee)
      store.encrypt(room_id: "!r:example.org", type: "m.room.message", content: {})
      store.flush_changes!

      store.export(pickle_key)[:outbound_sessions].should == []
    end
  end
