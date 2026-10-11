# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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
      # The encryption a client drives from its sync loop.
      #
      # It owns no connection and no loop: a client hands it each batch, and everything cryptographic is behind {Crypto}.
      class Machine
        # The algorithm a room is encrypted with.
        MEGOLM = "m.megolm.v1.aes-sha2"

        # @parameter client [Async::Matrix::ClientServer::Client] an authenticated client.
        # @parameter crypto [Crypto] the implementation to encrypt with.
        # @parameter store [Store] what to remember between batches.
        def initialize(client, crypto: Plaintext.new, store: Store.new)
          @client = client
          @crypto = crypto
          @store = store

          @devices = Devices.new(client)
          @events = Events.registry(client.version)

          @user_id = nil
          @device_id = nil
          @counts = {}
        end

        # @attribute [Crypto] the implementation which holds the key material.
        attr :crypto

        # @attribute [Devices] which devices each user has.
        attr :devices

        # @attribute [Store] what is remembered between batches.
        attr :store

        # @attribute [Hash] how many one time keys the server last reported holding.
        attr :counts

        # @returns [String] the user this machine encrypts as.
        def user_id
          @user_id ||= @client.get_token_owner.user_id
        end

        # @returns [String] the device this machine encrypts as.
        def device_id
          @device_id ||= @client.get_token_owner.device_id
        end

        # Publish this device's identity keys and a batch of one time keys.
        #
        # @returns [Async::Matrix::ClientServer::UploadedKeys] how many keys the server holds.
        def publish!
          @crypto.generate_one_time_keys(@crypto.one_time_key_target)

          uploaded = @client.keys.upload_keys(
            device_keys: self.device_keys,
            one_time_keys: self.signed_one_time_keys,
          )

          @crypto.published_one_time_keys!
          @counts = uploaded.one_time_key_counts

          Console.debug(self, "Published keys.", device_id: self.device_id, counts: @counts)

          uploaded
        end

        # The identity keys of this device, signed so that others can trust them.
        #
        # @returns [Hash] the device keys.
        def device_keys
          keys = @crypto.identity_keys.each_with_object({}) do |(algorithm, key), published|
            published[:"#{algorithm}:#{self.device_id}"] = key
          end

          unsigned = {
            user_id: self.user_id,
            device_id: self.device_id,
            algorithms: @crypto.algorithms,
            keys: keys,
          }

          unsigned.merge(signatures: self.signature_for(unsigned))
        end

        # The one time keys to publish, each signed on its own.
        #
        # @returns [Hash] the keys, by algorithm and ID.
        def signed_one_time_keys
          @crypto.one_time_keys.each_with_object({}) do |(id, key), published|
            unsigned = {key: key}

            published[id] = unsigned.merge(signatures: self.signature_for(unsigned))
          end
        end

        # Everything a sync batch says about encryption.
        #
        # @parameter sync [Async::Matrix::ClientServer::Sync] the batch.
        # @returns [Array(Async::Matrix::Events::Envelope)] the device events it carried.
        def receive(sync)
          @devices.receive(sync)
          @counts = sync.one_time_keys_count

          events = self.each_device_event(sync)

          Console.debug(self, "Received a batch.", events: events.size, changed: sync.changed_devices.size, left: sync.left_devices.size, counts: @counts)

          events.each do |event|
            self.receive_device_event(event)
          end
        end

        # The events addressed to this device, typed as the registry describes them.
        #
        # @parameter sync [Async::Matrix::ClientServer::Sync] the batch.
        # @returns [Array(Async::Matrix::Events::Envelope)] the events.
        def each_device_event(sync)
          sync.to_device.map{|value| @events.wrap(value)}
        end

        # Whether the server is running low on one time keys for this device.
        #
        # @returns [Boolean] whether to publish more.
        def one_time_keys_low?
          target = @crypto.one_time_key_target

          (@counts[:signed_curve25519] || 0) < target / 2
        end

        # Publish more one time keys, if the server is running low on them.
        #
        # @returns [Boolean] whether any were published.
        def top_up!
          if self.one_time_keys_low?
            self.publish!

            true
          else
            false
          end
        end

        # Share a session for a room with every device which should have it.
        #
        # The session the room already has is the one shared; a caller rotates when a device leaves.
        #
        # @parameter room_id [String] the room.
        # @parameter user_ids [Array(String)] the users whose devices to share with.
        # @parameter rotate [Boolean] whether to begin a new session first.
        # @returns [Hash] the session which was shared.
        def share(room_id, user_ids, rotate: false)
          self.session_for(room_id, rotate: rotate).tap do |session|
            recipients = @devices.recipients(user_ids, except: self.device_id)

            Console.debug(self, "Sharing a session.", room_id: room_id, session_id: session[:session_id], recipients: recipients.size, rotate: rotate)

            unless recipients.empty?
              @client.to_device.send_to_device("m.room_key", self.addressed(recipients, {
                algorithm: MEGOLM,
                room_id: room_id,
                session_id: session[:session_id],
                session_key: session[:session_key],
              }))
            end
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
            device_id: self.device_id,
            session_id: session[:session_id],
            ciphertext: @crypto.encrypt(room_id, plaintext),
          })
        end

        # Read an encrypted event, if the session it needs has arrived.
        #
        # An event which cannot be read is kept rather than raised, because its key may arrive later.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @parameter room_id [String] the room it arrived in, which an `m.room.encrypted` envelope does not carry.
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
            self.decrypted(event, room_id, session_id)
          end
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
              @store.remember(room_id, session_id: begun[:session_id], sender: self.user_id)

              Console.debug(self, "Began a session.", room_id: room_id, session_id: begun[:session_id], rotate: rotate)
            end
          end
        end

        private

        # Note what one device event means, which is how a session arrives.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the device event.
        def receive_device_event(event)
          case event.content
          when Events::RoomKey
            self.receive_room_key(event.content, event[:sender])
          when Events::RoomKeyWithheld
            content = event.content

            Console.debug(self, "A session was withheld.", sender: event[:sender], room_id: content[:room_id], session_id: content[:session_id], code: content.code)

            @store.refuse(content[:room_id], session_id: content[:session_id], code: content.code)
          else
            Console.debug(self, "Ignoring a device message which is not about keys.", sender: event[:sender], type: event.type)
          end
        end

        # @parameter content [Async::Matrix::Events::RoomKey] the session which was shared.
        # @parameter sender [String] the user who shared it.
        def receive_room_key(content, sender)
          room_id = content.room_id
          session_id = content.session_id

          Console.debug(self, "Accepting a session.", sender: sender, room_id: room_id, session_id: session_id, algorithm: content.algorithm)

          @crypto.create_inbound_session(room_id, session_id: session_id, session_key: content.session_key)
          @store.remember(room_id, session_id: session_id, sender: sender)
        end

        # Read an event with a session we hold, rebuilding the envelope it arrived in.
        #
        # @parameter event [Async::Matrix::Events::Envelope] the encrypted event.
        # @parameter room_id [String] the room it arrived in.
        # @parameter session_id [String] the session it belongs to.
        # @returns [Async::Matrix::Events::Envelope] the event it carried.
        def decrypted(event, room_id, session_id)
          plaintext = @crypto.decrypt(room_id, session_id: session_id, ciphertext: event.content[:ciphertext])
          payload = ::JSON.parse(plaintext, symbolize_names: true)

          Console.debug(self, "Read an encrypted event.", room_id: room_id, session_id: session_id, event_id: event[:event_id], type: payload[:type])

          @events.wrap(event.to_h.merge(type: payload[:type], content: payload[:content]), room_id: room_id)
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

        # The signature of this device over an object.
        #
        # @parameter object [Hash] the object to sign.
        # @returns [Hash] the signature, by user ID and then key.
        def signature_for(object)
          {self.user_id.to_sym => {:"ed25519:#{self.device_id}" => @crypto.sign(object)}}
        end
      end
    end
  end
end
