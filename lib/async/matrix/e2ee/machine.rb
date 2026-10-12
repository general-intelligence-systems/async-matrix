# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "console"
require "json"

require_relative "../events"
require_relative "canonical_json"
require_relative "devices"
require_relative "plaintext"
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

        # @parameter user_id [String] the user this device belongs to.
        # @parameter device_id [String] this device.
        # @parameter crypto [Crypto] the implementation to encrypt with.
        # @parameter store [Store] what to remember between batches.
        # @parameter devices [Devices] which devices each user has.
        # @parameter version [String] the specification version to read events as.
        def initialize(user_id:, device_id:, crypto: Plaintext.new, store: Store.new, devices: Devices.new, version: Async::Matrix::LATEST)
          @user_id = user_id
          @device_id = device_id

          @crypto = crypto
          @store = store
          @devices = devices

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

              Console.debug(self, "Began a session.", room_id: room_id, session_id: begun[:session_id], rotate: rotate)
            end
          end
        end

        # Every event in a batch which this device can read, and a marker where one it cannot would be.
        #
        # The device messages are drained first, so a key arriving in this batch releases the messages which were waiting for it, including ones from earlier batches. A released event is older than the batch which carried its key, so a caller ordering by arrival will put history out of order.
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
          in {type: 0, body: String => body} unless @crypto.session?(sender_key)
            self.believed(event, @crypto.accept_session(identity_key: sender_key, body: body), sender, sender_key)
          in {type: 0 | 1 => type, body: String => body}
            self.believed(event, @crypto.decrypt_from_device(sender_key, type: type, body: body), sender, sender_key)

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
        # The specification lists checks an incoming payload MUST pass, and says to discard anything which fails one. That is what this pattern is: a payload which does not match is never believed.
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
          in {type: String => type, content: Hash => content, sender: ^sender, recipient: ^@user_id, recipient_keys: {ed25519: ^ours}, keys: {ed25519: String => claimed}} if theirs.nil? || theirs.ed25519 == claimed
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
