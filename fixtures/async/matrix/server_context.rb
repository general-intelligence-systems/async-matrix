# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "digest"
require "securerandom"

require "sus/fixtures/async/reactor_context"

require "async/matrix"
require "async/matrix/server_key"
require "async/matrix/e2ee/canonical_json"

require_relative "client_context"

module Async
  module Matrix
    # The key the rig's homeserver signs for itself with, which is checked into `synapse/`.
    #
    # A homeserver verifies a signature made by its own server name against the key it already holds, rather than fetching one, so the suite can sign as the server it is testing and reach every authenticated endpoint. Nothing else would work: a server name invented here has no keys anybody could fetch.
    SIGNING_KEY = ENV.fetch("MATRIX_SIGNING_KEY", File.expand_path("../../../synapse/signing.key", __dir__))

    # The server name the homeserver under test answers for.
    SERVER_NAME = ENV.fetch("MATRIX_SERVER_NAME", "localhost")

    # A small PNG, so that a thumbnail can be made of it.
    #
    # A server thumbnails an image and refuses anything else, so a case which reads a thumbnail needs one file which really is an image. Sixty four pixels square, because a server only makes the sizes it is configured for and the smallest of those is thirty two.
    TEST_IMAGE = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAABA0lEQVR4nNXCkbYQAAAFwYUgCIIgeBAEQRAEQfAgCIIgCIIgCIIgCIKFIAiC" \
      "IAiCIAiCIAiCYCEIgiAIgiAIgiDoO+6cAdt+xKZz1KZzzKZz3KZzwqZz0qZzYNM5ZdM5bdM5Y9M5a9M5Z9M5b9O5YNO5aNM5tOlcsulctulc" \
      "selctelcs+lct+ncsOnctOncsunctuncsenctencs+nct+k8sOlo03lo03lk03ls03li03lq03lm03lu03lh03lp03ll03lt03lj03lr03ln" \
      "03lv0/lg0/lo08mm88mm89mm88Wm89Wm882m892m88Om89Om88um89um88em89em88+m/weZhmGl7ZNCxgAAAABJRU5ErkJggg=="
    ).freeze

    # What a redacted event keeps, by room version.
    module Redaction
      # The keys every room version keeps.
      KEYS = %w[event_id type room_id sender state_key content hashes signatures depth prev_events auth_events origin_server_ts].freeze

      # The keys room versions before 11 kept as well, which MSC2176 and MSC3989 took out.
      LEGACY_KEYS = %w[origin membership prev_state].freeze

      # The content keys kept, by event type. A type which is not listed keeps nothing.
      CONTENT = {
        "m.room.member" => %w[membership join_authorised_via_users_server],
        "m.room.join_rules" => %w[join_rule allow],
        "m.room.power_levels" => %w[ban events events_default invite kick redact state_default users users_default],
        "m.room.history_visibility" => %w[history_visibility],
        "m.room.redaction" => %w[redacts],
      }.freeze

      # The keys which are added after the event is signed, so are never signed over.
      UNSIGNED = %w[signatures unsigned age_ts outlier destination].freeze

      # Room version 11 was the first to redact the old top level keys away.
      MODERN = 11

      class << self
        # The event as it survives redaction, which is the form a signature is made over.
        #
        # The set is the room version's: a signature over the wrong keys is rejected.
        #
        # @parameter event [Hash] the event to redact, with string keys.
        # @parameter room_version [String] the room version whose rules apply.
        # @returns [Hash] the redacted event.
        def for(event, room_version)
          allowed = KEYS

          if room_version.to_i < MODERN
            allowed = KEYS + LEGACY_KEYS
          end

          content = (event["content"] || {}).select{|key, _| CONTENT.fetch(event["type"], []).include?(key)}

          event.select{|key, _| allowed.include?(key)}.merge("content" => content)
        end

        # The event without the keys which are added after signing.
        #
        # @parameter event [Hash] the event to strip.
        # @returns [Hash] the event, as it is signed.
        def signable(event)
          event.reject{|key, _| UNSIGNED.include?(key)}
        end

        # The same object with string keys, however deep.
        #
        # A template is read back through the JSON wrapper, which symbolises every key.
        #
        # @parameter object [Object] the object to convert.
        # @returns [Object] the same object, keyed by strings.
        def stringified(object)
          case object
          when Hash
            object.to_h{|key, value| [key.to_s, self.stringified(value)]}
          when Array
            object.map{|value| self.stringified(value)}
          else
            object
          end
        end
      end
    end

    # The server-server API, against the rig's own homeserver.
    #
    # A case makes the user, room and events it asks about over the client-server API, because there is nothing else to make them with: one homeserver cannot federate with itself.
    ServerContext = Sus::Shared("a matrix server") do
      include Sus::Fixtures::Async::ReactorContext

      # The resource every case makes its requests through, which is what the operations context watches.
      let(:unauthenticated) {Async::Matrix::ServerServer::Server[Async::Matrix::TEST_VERSION].open(Async::Matrix::HOMESERVER)}

      let(:key) {Async::Matrix::ServerKey.load(Async::Matrix::SIGNING_KEY)}

      let(:server_name) {Async::Matrix::SERVER_NAME}

      # Signed as the homeserver under test, which is the one server whose key the suite can have.
      let(:server) {unauthenticated.signed_as(self.server_name, self.key, self.server_name)}

      # The client-server API, which is how a case makes something to ask about.
      #
      # Deliberately not `unauthenticated`: that is the server-server resource, and a case named after an operation proves it made the call.
      let(:homeserver) {Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::HOMESERVER)}

      let(:username) {"fed-#{SecureRandom.hex(6)}"}

      let(:user_id) {"@#{self.username}:#{self.server_name}"}

      let(:client) {self.account(self.username)}

      let(:room) {client.create_room(name: Async::Matrix::TEST_ROOM_NAME, topic: Async::Matrix::TEST_ROOM_TOPIC, preset: "public_chat")}

      # An event in the room, so that a case has something to ask for by ID.
      let(:event) {room.send_message("m.room.message", {msgtype: "m.text", body: "over federation"})}

      # An authenticated client-server client, registering the account where the rig needs asking.
      #
      # @parameter username [String] the localpart to be.
      # @parameter through [Client] the unauthenticated client to log in through.
      # @returns [Client] a client authenticated as that user.
      def account(username, through: self.homeserver)
        if Async::Matrix::TEST_ACCOUNTS == "register"
          begin
            through.registration.register(username: username, password: Async::Matrix::TEST_PASSWORD, auth: {type: "m.login.dummy"}, inhibit_login: true)
          rescue Async::Matrix::RequestError => error
            unless error.errcode == "M_USER_IN_USE"
              raise
            end
          end
        end

        through.logged_in(username, Async::Matrix::TEST_PASSWORD)
      end

      # A user who is not in the room, which is who a join or a knock is made for.
      #
      # @returns [String] the user ID.
      def outsider
        @outsider ||= self.account("fed-#{SecureRandom.hex(6)}").get_token_owner.user_id
      end

      # The room version a room was created with, which decides how its events are signed.
      #
      # @parameter room [Room] the room to ask about.
      # @returns [String] the room version.
      def room_version_of(room)
        room.get_room_state_with_key("m.room.create").value[:room_version] || "1"
      end

      # An event the homeserver will accept: content hashed, then signed over its redacted form.
      #
      # It is the one thing `make_join` leaves to the caller.
      #
      # @parameter event [Hash] the template, with string keys.
      # @parameter room_version [String] the room version whose redaction rules apply.
      # @returns [Hash] the event, hashed and signed.
      def signed_event(event, room_version)
        event = Async::Matrix::Redaction.stringified(event)
        hashed = event.merge("hashes" => {"sha256" => self.content_hash(event)})
        redacted = Async::Matrix::Redaction.signable(Async::Matrix::Redaction.for(hashed, room_version))
        signatures = hashed["signatures"] || {}
        mine = signatures[self.server_name] || {}

        hashed.merge("signatures" => signatures.merge(self.server_name => mine.merge(self.key.id => self.key.sign(redacted))))
      end

      # The hash of everything the event says, which proves the parts redaction throws away.
      #
      # @parameter event [Hash] the event to hash.
      # @returns [String] the hash, as unpadded base64.
      def content_hash(event)
        stripped = Async::Matrix::Redaction.signable(event).reject{|key, _| key == "hashes"}

        Async::Matrix::ServerKey.encode(Digest::SHA256.digest(Async::Matrix::E2EE::CanonicalJSON.dump(stripped)))
      end

      # The ID an event has, which is the hash of its redacted form rather than a name it carries.
      #
      # @parameter event [Hash] the signed event.
      # @parameter room_version [String] the room version whose rules apply.
      # @returns [String] the event ID.
      def event_id_of(event, room_version)
        redacted = Async::Matrix::Redaction.signable(Async::Matrix::Redaction.for(Async::Matrix::Redaction.stringified(event), room_version))
        digest = Digest::SHA256.digest(Async::Matrix::E2EE::CanonicalJSON.dump(redacted))

        "$#{Base64.urlsafe_encode64(digest, padding: false)}"
      end

      after do
        # Every resource and representation shares its root's connection, so closing the root closes all of them:
        @unauthenticated&.close
        @homeserver&.close
      end
    end
  end
end
