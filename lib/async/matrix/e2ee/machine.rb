# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "console"
require "json"

require_relative "../events"
require_relative "backup"
require_relative "canonical_json"
require_relative "cross_signing"
require_relative "devices"
require_relative "plaintext"
require_relative "secrets"
require_relative "store"

module Async
  module Matrix
    module E2EE
      # The key material and session state a device encrypts with.
      #
      # It makes no request: a caller hands it what the homeserver said, and it answers with what to send.
      class Machine
        # The algorithm a room is encrypted with.
        MEGOLM = "m.megolm.v1.aes-sha2"

        # The algorithm a device is encrypted to, which is how every key travels.
        OLM = "m.olm.v1.curve25519-aes-sha2"

        # How long a session may be used for, where the room says nothing: a week.
        DEFAULT_PERIOD = 604_800_000

        # How many messages a session may carry, where the room says nothing.
        DEFAULT_MESSAGES = 100

        # The history visibilities which let a session be passed on to a later member.
        SHAREABLE = ["shared", "world_readable"].freeze

        # Which part of the identity each of the three cross signing secrets carries.
        CROSS_SIGNING = {
          "m.cross_signing.master" => :master,
          "m.cross_signing.self_signing" => :self_signing,
          "m.cross_signing.user_signing" => :user_signing,
        }.freeze

        # @parameter user_id [String] the user this device belongs to.
        # @parameter device_id [String] this device.
        # @parameter crypto [Crypto] the implementation to encrypt with.
        # @parameter store [Store] what to remember between batches.
        # @parameter devices [Devices] which devices each user has.
        # @parameter version [String] the specification version to read events as.
        def initialize(user_id:, device_id:, crypto: Plaintext.new, store: Store.new, devices: nil, version: Async::Matrix::LATEST)
          @user_id = user_id
          @device_id = device_id

          @crypto = crypto
          @store = store
          @secrets = Secrets.new

          # Our own cross signing identity, which is empty until it is created or opened from storage.
          @identity = CrossSigning.new(user_id)
          @devices = devices || Devices.new(crypto: crypto)

          # What each room's state said, since the machine cannot ask and a rotation turns on it.
          @rooms = {}

          @events = Events.registry(version)

          # What a key released, which is yielded after the device messages which carried it.
          @released = []
        end

        # @attribute [String] the user this device encrypts as.
        attr :user_id

        # @attribute [String] the device this device encrypts as.
        attr :device_id

        # @attribute [Crypto] the implementation which holds the key material.
        attr :crypto

        # @attribute [Devices] which devices each user has.
        attr :devices

        # @attribute [Store] what is remembered between batches.
        attr :store

        # @attribute [Secrets] the private keys this device holds.
        attr :secrets

        # The identity keys of this device, signed so that others can trust them.
        #
        # @returns [Hash] the device keys.
        def device_keys
          keys = @crypto.identity_keys.each_with_object({}) do |(algorithm, key), published|
            published[:"#{algorithm}:#{@device_id}"] = key
          end

          unsigned = {
            user_id: @user_id,
            device_id: @device_id,
            algorithms: @crypto.algorithms,
            keys: keys,
          }

          unsigned.merge(signatures: self.signature_for(unsigned))
        end

        # The one time keys to publish, each signed on its own.
        #
        # @returns [Hash] the keys, by algorithm and ID.
        def signed_one_time_keys
          self.signed(@crypto.one_time_keys)
        end

        # The fallback key to publish, which says that it is one.
        #
        # @returns [Hash] the key, by algorithm and ID.
        def signed_fallback_key
          self.signed(@crypto.fallback_key, fallback: true)
        end

        # Whether the server is running low on one time keys for this device.
        #
        # @parameter counts [Hash] what the batch said the server holds.
        # @returns [Boolean] whether to publish more.
        def one_time_keys_low?(counts)
          (counts[:signed_curve25519] || 0) < @crypto.one_time_key_target / 2
        end

        # @attribute [CrossSigning] our own identity, as far as this device holds it.
        attr :identity

        # A whole new cross signing identity, which replaces whatever the user had.
        #
        # @returns [CrossSigning] the three keys, whose private halves belong in secret storage.
        def create_cross_signing_keys
          @identity = CrossSigning.generate(@user_id)
        end

        # Take on one of our own cross signing keys, which arrived from storage or from a sibling device.
        #
        # @parameter name [String] which secret it is, e.g. `m.cross_signing.self_signing`.
        # @parameter secret [String] the private key, base64 encoded.
        # @returns [CrossSigning | nil] our identity, or nil where the name is not one of the three.
        def accept_cross_signing_secret(name, secret)
          part = CROSS_SIGNING[name.to_s]

          if part.nil?
            Console.warn(self, "That is not a cross signing key.", name: name)

            nil
          else
            @identity[part] = CrossSigning::Key.from_base64(secret)

            Console.info(self, "Took on a cross signing key.", name: name)

            @identity
          end
        end

        # Sign this device with our own self signing key, which is what makes it cross signed.
        #
        # @returns [Hash | nil] the signatures to upload, or nil without the key to write them.
        def sign_own_device
          @identity.sign_device(self.device_keys)
        end

        # Sign what a verification established, so that it holds for every device rather than this one.
        #
        # @parameter keys [Array(String)] the keys which were verified.
        # @returns [Array(Hash)] the signatures to upload, which is none where we cannot sign.
        def sign_verified(keys)
          keys.filter_map do |key|
            user_id = @devices.identities.find{|_, held| held[:master] == key}&.first

            case user_id
            in String => whose
              @identity.sign_master(whose, @devices.identity(whose)[:object])
            in nil
              Console.warn(self, "Nothing is known about the key which was verified.", key: key)

              nil
            end
          end
        end

        # @parameter user_id [String] the user.
        # @parameter device_id [String] the device.
        # @returns [Boolean] whether that device carries its owner's signature.
        def cross_signed?(user_id, device_id)
          @devices[user_id, device_id]&.cross_signed? == true
        end

        # Whether our own user signing key signed this identity, which is what verifying somebody leaves behind.
        #
        # @parameter user_id [String] whose identity it is.
        # @parameter master [String] their master key.
        # @returns [Boolean] whether we signed it.
        def signed_by_us?(user_id, master)
          signing = @identity.user_signing_key
          object = @devices.identity(user_id)&.fetch(:object, nil)

          case {signing: signing, object: object}
          in {signing: String => key, object: {signatures: Hash => signatures}}
            signatures.each_value.any?{|held| held.key?(:"ed25519:#{key}")}
          else
            false
          end
        end

        # Whether the device which encrypted an event carries its owner's signature.
        #
        # A message from a device nothing vouches for cannot be shown as though somebody did.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the event.
        # @returns [Boolean] whether its sender can be placed.
        def cross_signed_sender?(event)
          case event
          in {session_id: String => session_id, sender: String => sender}
            @store.sender_device(session_id).then do |device_id|
              case device_id
              in String => held
                self.cross_signed?(sender, held)
              in nil
                @devices.of(sender).any?(&:cross_signed?)
              end
            end
          else
            false
          end
        end

        # Every session this device holds, which is what a backup or an export is made of.
        #
        # @returns [Array(Hash)] the sessions, by room and session ID.
        def sessions
          @store.sessions.map do |(room_id, session_id), held|
            {room_id: room_id, session_id: session_id, **held}
          end
        end

        # One session, as a backup wants it.
        #
        # @parameter session [Hash] the session, as {#sessions} answers it.
        # @returns [Hash] the fields a backup is written from.
        def export_for_backup(session)
          room_id = session[:room_id]
          session_id = session[:session_id]
          index = @store.first_known_index(room_id, session_id)

          {
            room_id: room_id,
            session_id: session_id,
            algorithm: MEGOLM,
            session_key: @crypto.export_session(session_id, index: index),
            sender_key: session[:sender_key],
            sender_claimed_keys: session[:sender_claimed_keys] || {},
            forwarding_curve25519_key_chain: session[:forwarding_curve25519_key_chain] || [],
            shared_history: session[:shared_history] || false,
            first_message_index: index,
            forwarded_count: (session[:forwarding_curve25519_key_chain] || []).size,
            # A restored session carries no signature, so what it claims about its sender is only as good as whoever put it there: this is what the sender's device was, not what the backup says.
            is_verified: @devices.verified?(session[:sender], session[:device_id].to_s),
          }
        end

        # Accept a session which arrived without a signature of its own.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session.
        # @parameter session_key [String] the exported key.
        # @parameter sender [String | nil] who it is claimed to have come from.
        # @parameter shareable [Boolean] whether its creator meant it to travel.
        def import_inbound_session(room_id, session_id:, session_key:, sender: nil, shareable: false, **rest)
          @crypto.import_inbound_session(room_id, session_id: session_id, exported_key: session_key)
          @store.remember(room_id, session_id: session_id, sender: sender, imported: true, shareable: shareable, **rest)

          Console.debug(self, "Imported a session.", room_id: room_id, session_id: session_id, sender: sender)

          self.release(room_id, session_id)
        end

        # The master key of our own cross signing identity, where there is one.
        #
        # @returns [String | nil] the key.
        def own_master_key
          @devices.identity(@user_id)&.fetch(:master, nil)
        end

        # Sign an object as this device, which is how a backup is claimed as ours.
        #
        # @parameter object [Hash] what to sign.
        # @returns [Hash] the object, with this device's signature added.
        def sign_as_own(object)
          object.merge(signatures: self.signature_for(object))
        end

        # Whether an object carries a signature by any of these keys.
        #
        # @parameter object [Hash] the signed object.
        # @parameter by [String | Array | nil] the keys, or the devices holding them.
        # @returns [Boolean] whether one of them signed it.
        def verify_signatures(object, by:)
          signatures = object[:signatures] || {}
          unsigned = object.reject{|name, _| name == :signatures}

          self.class.keys_of(by).any? do |key|
            signed = signatures.each_value.filter_map{|held| held[:"ed25519:#{key}"]}

            signed.any?{|signature| @crypto.verify(unsigned, key: key, signature: signature)}
          end
        end

        # The ed25519 keys a caller named, however it named them.
        #
        # @parameter by [String | Array | nil] a key, the devices holding them, or nothing.
        # @returns [Array(String)] the keys.
        def self.keys_of(by)
          case by
          in nil
            []
          in String => key
            [key]
          in Array => named
            named.filter_map do |one|
              case one
              in String => key
                key
              in Device => device
                device.ed25519
              else
                nil
              end
            end
          end
        end

        # Note what a room's encryption state says, which is what a rotation is measured against.
        #
        # @parameter room_id [String] the room.
        # @parameter period [Integer | nil] how long a session may be used for, in milliseconds.
        # @parameter messages [Integer | nil] how many messages a session may carry.
        def policy(room_id, period: nil, messages: nil)
          room = (@rooms[room_id] ||= {})

          room[:encrypted] = true
          room[:period] = period || DEFAULT_PERIOD
          room[:messages] = messages || DEFAULT_MESSAGES
        end

        # Note what a room's history visibility says, which decides whether a session may be passed on.
        #
        # @parameter room_id [String] the room.
        # @parameter visibility [String] what the state event said.
        def history(room_id, visibility)
          (@rooms[room_id] ||= {})[:visibility] = visibility
        end

        # @parameter room_id [String] the room.
        # @returns [Boolean] whether this room is known to be encrypted.
        def encrypted?(room_id)
          @rooms.dig(room_id, :encrypted) == true
        end

        # Whether a session for this room may be given to somebody who joins later.
        #
        # @parameter room_id [String] the room.
        # @returns [Boolean] whether the history is shared.
        def shared_history?(room_id)
          # True only while the history is visible to them, which is what the flag on a shared key reports.
          SHAREABLE.include?(@rooms.dig(room_id, :visibility))
        end

        # The rooms whose session has been used for too long, or for too many messages.
        #
        # @returns [Hash] why each room is due, by room ID.
        def rooms_due_for_rotation
          # Neither is an event, so neither can be noticed by reading one: they are measured here instead.
          @rooms.each_with_object({}) do |(room_id, room), due|
            session = @crypto.session_for(room_id)

            case self.overdue(room_id, room, session)
            in String => because
              due[room_id] = because
            else
              nil
            end
          end
        end

        # Take on what a device list query answered.
        #
        # @parameter queried [Async::Matrix::ClientServer::QueriedKeys] what the homeserver said.
        def accept_queried_keys(queried)
          @devices.accept(queried)
        end

        # Open a session with each device a one time key was claimed for.
        #
        # @parameter claimed [Async::Matrix::ClientServer::ClaimedKeys] the keys the homeserver handed out.
        # @returns [Array(Device)] the devices a session was opened with.
        def accept_claimed_keys(claimed)
          claimed.one_time_keys.flat_map do |user_id, devices|
            devices.filter_map do |device_id, keys|
              self.open_session(user_id.to_s, device_id.to_s, keys)
            end
          end
        end

        # Forget the users we no longer share an encrypted room with.
        #
        # @parameter user_ids [Array(String)] the users to forget.
        def forget(user_ids)
          @devices.invalidate(left: user_ids)
        end

        # The devices to encrypt to, out of what a query answered.
        #
        # @parameter queried [Async::Matrix::ClientServer::QueriedKeys] what the homeserver said.
        # @returns [Array(Device)] the devices, without this one and without the blocked.
        def recipients(queried)
          @devices.accept(queried)

          @devices.recipients(queried.device_keys.keys.map(&:to_s), except: @device_id)
        end

        # Which of these devices there is no Olm session with yet.
        #
        # The answer is what `/keys/claim` is asked for, so it is shaped as that endpoint wants.
        #
        # @parameter devices [Array(Device)] the devices to address.
        # @parameter force [Boolean] whether to ask again for devices a session already exists with.
        # @returns [Hash] the algorithm wanted, by user ID and then device ID.
        def without_sessions(devices, force: false)
          devices.each_with_object({}) do |device, wanted|
            if force or !@crypto.session?(device.curve25519)
              (wanted[device.user_id] ||= {})[device.device_id] = "signed_curve25519"
            end
          end
        end

        # Encrypt an event to one device, which is how every key is delivered.
        #
        # @parameter device [Device] the device to encrypt for.
        # @parameter type [String] the type of the event inside.
        # @parameter content [Hash] the content of the event inside.
        # @returns [Hash] the content of an `m.room.encrypted` addressed to that device.
        def encrypt_to_device(device, type, content)
          plaintext = CanonicalJSON.dump(self.olm_payload(device, type, content))
          message, body = @crypto.encrypt_to_device(device.curve25519, plaintext)

          Console.debug(self, "Encrypted to a device.", user_id: device.user_id, device_id: device.device_id, type: type)

          {
            algorithm: OLM,
            sender_key: @crypto.identity_keys[:curve25519],
            ciphertext: {device.curve25519 => {type: message, body: body}},
          }
        end

        # The same content, addressed to each of these devices.
        #
        # @parameter devices [Array(Device)] the devices to address.
        # @parameter content [Hash] what to send to each of them.
        # @returns [Hash] the messages, by user ID and then device ID.
        def addressed(devices, content)
          devices.each_with_object({}) do |device, messages|
            (messages[device.user_id] ||= {})[device.device_id] = content
          end
        end

        # The content to send into a room, in place of the event itself.
        #
        # @parameter room_id [String] the room.
        # @parameter content [Async::Matrix::Events::Content] what to encrypt.
        # @returns [Async::Matrix::Events::Content] the encrypted content.
        def encrypt(room_id, content)
          session = self.session_for(room_id)

          plaintext = CanonicalJSON.dump({type: content.type, room_id: room_id, content: content.to_h})

          Console.debug(self, "Encrypting an event.", room_id: room_id, session_id: session[:session_id], type: content.type)

          @events.content("m.room.encrypted", {
            algorithm: MEGOLM,
            sender_key: @crypto.identity_keys[:curve25519],
            device_id: @device_id,
            session_id: session[:session_id],
            ciphertext: @crypto.encrypt(room_id, plaintext),
          })
        end

        # The session this device encrypts a room with, begun if there is none.
        #
        # Our own session is remembered, because a message we sent comes back in sync like anybody else's.
        #
        # @parameter room_id [String] the room.
        # @parameter rotate [Boolean] whether to begin a new session regardless.
        # @returns [Hash] the session.
        def session_for(room_id, rotate: false)
          session = @crypto.session_for(room_id)

          if session and !rotate
            session
          else
            @crypto.create_outbound_session(room_id).tap do |begun|
              @store.remember(room_id, session_id: begun[:session_id], sender: @user_id)
              @store.starting(room_id)

              Console.debug(self, "Began a session.", room_id: room_id, session_id: begun[:session_id], rotate: rotate)
            end
          end
        end

        # Every event in a batch, read where it can be and marked where it cannot.
        #
        # The device messages drain first, so a key here releases what waited for it.
        #
        # @parameter sync [Async::Matrix::ClientServer::Sync] the batch.
        # @parameter replay [Boolean] whether to yield the events a key released.
        # @yields {|event| ...}
        #   @parameter event [Async::Matrix::Events::Envelope] the event.
        def each_event(sync, replay: true)
          if block_given?
            sync.to_device.each do |value|
              self.each_device_event(value) do |event|
                yield event
              end
            end

            if replay
              @released.each do |event|
                yield event
              end
            end

            @released = []

            sync.each_event do |event|
              self.note(event)

              case event.content
              when Events::RoomEncrypted
                yield self.read(event)
              else
                yield event
              end
            end
          else
            to_enum(:each_event, sync, replay: replay)
          end
        end

        # One device message, read if it is encrypted and yielded as what it carried.
        #
        # @parameter value [Hash] the event, as the batch carried it.
        # @yields {|event| ...}
        #   @parameter event [Async::Matrix::Events::Envelope] the event.
        def each_device_event(value)
          event = @events.wrap(value)
          content = event.content

          case content
          when Events::RoomEncrypted
            opened = self.open(event)

            if opened
              @released.concat(self.receive_device_event(opened.content, sender: opened.sender))

              yield opened
            end
          else
            @released.concat(self.receive_device_event(content, sender: event[:sender]))

            yield event
          end
        end

        # Read an encrypted event, if the session it needs has arrived.
        #
        # An event which cannot be read is kept rather than raised, because its key may arrive later.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @parameter room_id [String] the room it arrived in.
        # @returns [Async::Matrix::Events::Envelope | nil] the event it carried.
        def decrypt(event, room_id: event[:room_id])
          content = event.content
          session_id = content[:session_id]

          unless @store.session?(room_id, session_id)
            Console.debug(self, "Deferred an event, whose session has not arrived.", room_id: room_id, session_id: session_id, withheld: @store.refused(room_id, session_id))

            @store.defer(room_id, session_id: session_id, event: event)

            nil
          else
            self.decrypted(event, room_id, session_id)
          end
        end

        # The events which were waiting for a session, now that it has arrived.
        #
        # @parameter room_id [String] the room.
        # @parameter session_id [String] the session which arrived.
        # @returns [Array(Async::Matrix::Events::Envelope)] what can now be read.
        def release(room_id, session_id)
          deferred = @store.deferred(room_id, session_id)

          Console.debug(self, "Releasing the events which were waiting.", room_id: room_id, session_id: session_id, events: deferred.size)

          deferred.filter_map do |event|
            self.decrypted(event, room_id, session_id, released: true)
          end
        end

        # One event, typed as the registry describes it.
        #
        # @parameter value [Hash] the event.
        # @parameter room_id [String | nil] the room it came from, which sync names once per room.
        # @returns [Async::Matrix::Events::Envelope] the event.
        def wrap(value, room_id: nil)
          @events.wrap(value, room_id: room_id)
        end

        # One content, typed as the registry describes it.
        #
        # @parameter type [String] the event type.
        # @parameter value [Hash] the content.
        # @returns [Async::Matrix::Events::Content] the content.
        def content(type, value)
          @events.content(type, value)
        end

        # Note what one device event means, which is how a session arrives.
        #
        # @parameter content [Async::Matrix::Events::Content] what the event carried.
        # @parameter sender [String] the user who sent it.
        # @returns [Array(Async::Matrix::Events::Envelope)] the events this released, if any.
        def receive_device_event(content, sender:)
          case content
          when Events::RoomKey
            self.receive_room_key(content, sender)
          when Events::RoomKeyWithheld
            Console.debug(self, "A session was withheld.", sender: sender, room_id: content[:room_id], session_id: content[:session_id], code: content.code)

            @store.refuse(content[:room_id], session_id: content[:session_id], code: content.code)

            []
          else
            Console.debug(self, "Ignoring a device message which is not about keys.", sender: sender, type: content.type)

            []
          end
        end

        private

        # Note the room state an event carries, so that a rotation can be measured without asking.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the event.
        def note(event)
          case event
          in {room_id: String => room_id, content: Events::RoomEncryption => content}
            self.policy(room_id, period: content[:rotation_period_ms], messages: content[:rotation_period_msgs])
          in {room_id: String => room_id, content: Events::RoomHistoryVisibility => content}
            self.history(room_id, content[:history_visibility])
          else
            nil
          end
        end

        # Why a room's session should be replaced, if it should.
        #
        # @parameter room_id [String] the room.
        # @parameter room [Hash] what its state said.
        # @parameter session [Hash | nil] the session it is on.
        # @returns [String | nil] the reason, or nil while it may still be used.
        def overdue(room_id, room, session)
          case session
          in nil
            nil
          in {message_index: Integer => index}
            if index >= room.fetch(:messages, DEFAULT_MESSAGES)
              "it has carried #{index} messages"
            else
              self.expired(room_id, room)
            end
          else
            self.expired(room_id, room)
          end
        end

        # Why the room's session is too old to go on using, if it is.
        #
        # @parameter room_id [String] the room.
        # @parameter room [Hash] what its state said.
        # @returns [String | nil] the reason, or nil while it may still be used.
        def expired(room_id, room)
          started = @store.started(room_id)

          case started
          in Time => at
            if (Time.now - at) * 1000 >= room.fetch(:period, DEFAULT_PERIOD)
              "it has been in use since #{at}"
            else
              nil
            end
          else
            nil
          end
        end

        # Read a timeline event, answering a marker where it cannot be read.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @returns [Async::Matrix::Events::Envelope] the plaintext, or why there is none.
        def read(event)
          content = event.content
          room_id = event.room_id
          session_id = content.session_id

          case {held: @store.session?(room_id, session_id), refused: @store.refused(room_id, session_id)}
          # Deliberately refused, so the wait is over and the reason is known.
          in {refused: String => code}
            self.unreadable(event, Events::Withheld, code: code)

          # Not here yet, which it may still be: the event is kept for when the key arrives.
          in {held: false}
            Console.debug(self, "Deferred an event, whose session has not arrived.", room_id: room_id, session_id: session_id)

            @store.defer(room_id, session_id: session_id, event: event)

            self.unreadable(event, Events::Deferred)

          in {held: true}
            self.decrypted(event, room_id, session_id)
          end
        rescue => error
          Console.error(self, "Could not read an event.", room_id: event.room_id, session_id: event.content.session_id, error: error)

          self.unreadable(event, Events::Undecryptable, reason: error.message)
        end

        # Read a device message, which is Olm encrypted and names its own sender and recipient.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @returns [Async::Matrix::Events::Decrypted | nil] what it carried, or nil when it was not for us.
        def open(event)
          content = event.content
          sender = event[:sender]
          sender_key = content.sender_key

          addressed = (content.ciphertext || {})[@crypto.identity_keys[:curve25519].to_sym]

          case addressed
          # A type 0 carries the session, so it opens one when there is none to read it with.
          in {type: 0, body: String => body}
            # A session already open is what a type 0 is read with; otherwise the message carries one.
            case @crypto.session?(sender_key)
            in true
              self.believed(event, @crypto.decrypt_from_device(sender_key, type: 0, body: body), sender, sender_key)
            in false
              self.believed(event, @crypto.accept_session(identity_key: sender_key, body: body), sender, sender_key)
            end

          in {type: 1, body: String => body}
            self.believed(event, @crypto.decrypt_from_device(sender_key, type: 1, body: body), sender, sender_key)

          # One event carries a copy per device, so most of them are not for this one.
          else
            nil
          end
        rescue => error
          Console.error(self, "Could not read a device message.", sender: sender, error: error)

          @events.wrap(event.to_h.merge(
            type: Events::Undecryptable.event_type,
            content: {algorithm: OLM, sender_key: sender_key, reason: error.message},
          ))
        end

        # What an Olm plaintext decrypted to, if it is what it claims to be.
        #
        # The checks the specification demands are this one pattern, and what fails it is discarded.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the envelope it arrived in.
        # @parameter plaintext [String] what it decrypted to.
        # @parameter sender [String] who the envelope said sent it.
        # @parameter sender_key [String] the key it was encrypted with.
        # @returns [Async::Matrix::Events::Decrypted | nil] the event it carried, or nil if it is not believed.
        def believed(event, plaintext, sender, sender_key)
          payload = ::JSON.parse(plaintext, symbolize_names: true)
          theirs = @devices.by_curve25519(sender, sender_key)
          ours = @crypto.identity_keys[:ed25519]

          case payload
          in {type: String => type, content: Hash => content, sender: ^sender, recipient: ^@user_id, recipient_keys: {ed25519: ^ours}, keys: {ed25519: ^(theirs&.ed25519 || payload.dig(:keys, :ed25519))}}
            Events::Decrypted.new(
              event.to_h.merge(type: type),
              @events.content(type, content),
              sender_device_keys: payload.key?(:sender_device_keys),
            )
          else
            Console.error(self, "Discarded a device message which does not name us and its sender correctly.", sender: sender, type: payload[:type])

            nil
          end
        end

        # A marker where a message which cannot be read would have been.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @parameter type [Class] which marker to build.
        # @parameter fields [Hash] what else is known about why.
        # @returns [Async::Matrix::Events::Envelope] the marker, in the envelope the ciphertext arrived in.
        def unreadable(event, type, **fields)
          content = event.content

          @events.wrap(event.to_h.merge(
            type: type.event_type,
            content: {
              algorithm: content.algorithm,
              room_id: event.room_id,
              session_id: content.session_id,
              sender_key: content.sender_key,
              **fields,
            },
          ), room_id: event.room_id)
        end

        # @parameter content [Async::Matrix::Events::RoomKey] the session which was shared.
        # @parameter sender [String] the user who shared it.
        # @returns [Array(Async::Matrix::Events::Envelope)] the events this released.
        def receive_room_key(content, sender)
          room_id = content.room_id
          session_id = content.session_id

          Console.debug(self, "Accepting a session.", sender: sender, room_id: room_id, session_id: session_id, algorithm: content.algorithm)

          @crypto.create_inbound_session(room_id, session_id: session_id, session_key: content.session_key)
          @store.remember(room_id, session_id: session_id, sender: sender)

          self.release(room_id, session_id)
        end

        # Read an event with a session we hold, rebuilding the envelope it arrived in.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @parameter room_id [String] the room it arrived in.
        # @parameter session_id [String] the session it belongs to.
        # @returns [Async::Matrix::Events::Envelope] the event it carried.
        def decrypted(event, room_id, session_id, released: false)
          plaintext, message_index = @crypto.decrypt(room_id, session_id: session_id, ciphertext: event.content[:ciphertext])
          payload = ::JSON.parse(plaintext, symbolize_names: true)

          Console.debug(self, "Read an encrypted event.", room_id: room_id, session_id: session_id, event_id: event[:event_id], type: payload[:type], message_index: message_index)

          Events::Decrypted.new(
            event.to_h.merge(type: payload[:type]),
            @events.content(payload[:type], payload[:content] || {}),
            room_id: room_id,
            session_id: session_id,
            message_index: message_index,
            released: released,
          )
        end

        # Open an Olm session with one device, from the keys claimed for it.
        #
        # @parameter user_id [String] the user.
        # @parameter device_id [String] the device.
        # @parameter keys [Hash] the one time keys the homeserver handed out for it.
        # @returns [Device | nil] the device a session was opened with.
        def open_session(user_id, device_id, keys)
          device = @devices.of(user_id).find{|known| known.device_id == device_id}
          key = keys.each_value.first

          case {device: device, key: key}
          in {device: Device => found, key: {key: String => one_time_key}}
            @crypto.open_session(identity_key: found.curve25519, one_time_key: one_time_key)

            Console.debug(self, "Opened a session.", user_id: user_id, device_id: device_id)

            found
          else
            Console.warn(self, "Could not open a session, because the claim answered nothing usable.", user_id: user_id, device_id: device_id)

            nil
          end
        end

        # Each of these keys, signed on its own as the upload wants them.
        #
        # @parameter keys [Hash] the keys, by ID.
        # @parameter fallback [Boolean] whether to mark them as fallback keys.
        # @returns [Hash] the signed keys, by ID.
        def signed(keys, fallback: false)
          keys.each_with_object({}) do |(id, key), published|
            unsigned = {key: key}

            if fallback
              unsigned[:fallback] = true
            end

            published[id] = unsigned.merge(signatures: self.signature_for(unsigned))
          end
        end

        # What an Olm encrypted event carries, which is what the recipient validates.
        #
        # @parameter device [Device] the device it is addressed to.
        # @parameter type [String] the type of the event inside.
        # @parameter content [Hash] the content of the event inside.
        # @returns [Hash] the payload.
        def olm_payload(device, type, content)
          {
            type: type,
            content: content,
            sender: @user_id,
            recipient: device.user_id,
            recipient_keys: {ed25519: device.ed25519},
            keys: {ed25519: @crypto.identity_keys[:ed25519]},
            sender_device_keys: self.device_keys,
          }
        end

        # The signature of this device over an object.
        #
        # @parameter object [Hash] the object to sign.
        # @returns [Hash] the signature, by user ID and then key.
        def signature_for(object)
          {@user_id.to_sym => {:"ed25519:#{@device_id}" => @crypto.sign(object)}}
        end
      end
    end
  end
end
