# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

module Async
  module Matrix
    class Client
      # The endpoints that make a device exist, be reachable, and be able to
      # share keys. Mixed into Client.
      #
      # ORDER MATTERS, and it is the one thing a reader needs from this file:
      #
      #   register_user      the account exists (appservices only)
      #   create_device      the device exists, without /login (MSC4190)
      #   upload_keys        other devices can now find and reach us
      #   query_keys         we learn who else is in the room, and their keys
      #   claim_keys         we take a key to open a session with one of them
      #   send_to_device     we hand them a room key through that session
      #
      # Until `upload_keys` has run the device is invisible: nobody can claim a
      # one-time key, so nobody can open an Olm session, so nobody can send us a
      # room key, and every message in an encrypted room stays ciphertext. It is
      # a precondition, not an optimisation.
      #
      # Every method routes through #api, so the path is validated against the
      # vendored OpenAPI tree before a request is made -- a typo is an
      # InvalidEndpointError here rather than a 404 from the homeserver.
      module Encryption
        # ── Publishing our own keys ───────────────────────────────────────────

        # POST /keys/upload. Any combination of the three may be sent; a nil is
        # omitted rather than sent as null.
        #
        # @parameter device_keys [Hash] from Protocol::Matrix::Keys.device_keys
        # @parameter one_time_keys [Hash] from Keys.one_time_keys
        # @parameter fallback_keys [Hash] from Keys.fallback_keys
        # @returns [Hash] with `one_time_key_counts`, which is what tells us how
        #   many the server now holds.
        def upload_keys(device_keys: nil, one_time_keys: nil, fallback_keys: nil)
          body = {}

          if device_keys
            body[:device_keys] = device_keys
          end

          unless one_time_keys.nil? || one_time_keys.empty?
            body[:one_time_keys] = one_time_keys
          end

          unless fallback_keys.nil? || fallback_keys.empty?
            body[:fallback_keys] = fallback_keys
          end

          api.keys.upload.post(body)
        end

        # POST /keys/device_signing/upload -- the cross-signing keys.
        #
        # MSC4190 removed the user-interactive auth requirement here for
        # appservices, which is what makes this reachable without a password.
        # It matters because MSC4153 lets senders refuse to share room keys with
        # a device that is not cross-signed.
        def upload_cross_signing_keys(master_key: nil, self_signing_key: nil, user_signing_key: nil)
          body = {}

          if master_key
            body[:master_key] = master_key
          end

          if self_signing_key
            body[:self_signing_key] = self_signing_key
          end

          if user_signing_key
            body[:user_signing_key] = user_signing_key
          end

          api.keys.device_signing.upload.post(body)
        end

        # POST /keys/signatures/upload -- our signatures over other keys.
        def upload_signatures(signatures)
          api.keys.signatures.upload.post(signatures)
        end

        # ── Learning about other devices ──────────────────────────────────────

        # POST /keys/query. +user_ids+ is who to ask about; an empty device list
        # per user means "all of their devices".
        #
        # @parameter token [String] the `device_lists` sync token, so the server
        #   can tell us whether our view is already current.
        def query_keys(user_ids:, token: nil)
          body = {device_keys: user_ids.to_h { |user_id| [user_id, []] }}

          if token
            body[:token] = token
          end

          api.keys.query.post(body)
        end

        # POST /keys/claim -- take one one-time key per device, to open a
        # session.
        #
        # ONLY FOR DEVICES WE HAVE NO SESSION WITH. Each claim consumes a key
        # from a finite pool, so claiming for a device we can already reach
        # burns one for nothing.
        #
        # @parameter devices [Hash] { "@user:server" => ["DEVICEID", ...] }
        def claim_keys(devices:, algorithm: Protocol::Matrix::Keys::SIGNED_CURVE25519, timeout: nil)
          body = {
            one_time_keys: devices.transform_values { |ids|
              ids.to_h { |device_id| [device_id, algorithm] }
            },
          }

          if timeout
            body[:timeout] = timeout
          end

          api.keys.claim.post(body)
        end

        # ── Talking to devices directly ───────────────────────────────────────

        # PUT /sendToDevice/{eventType}/{txnId}
        #
        # @parameter messages [Hash] { "@user:server" => { "DEVICEID" => content } }
        #
        # This is how a room key travels. The transaction id makes it
        # idempotent, so a retry after a timeout cannot deliver twice.
        def send_to_device(event_type:, messages:, txn_id: nil)
          api.sendToDevice(event_type, txn_id || SecureRandom.uuid).put({messages: messages})
        end

        # ── Device lifecycle ──────────────────────────────────────────────────

        # PUT /devices/{deviceId} -- MSC4190.
        #
        # THE REASON THIS EXISTS: appservices used to create devices by calling
        # /login with `m.login.application_service`, and that route is gone on a
        # homeserver fronted by OAuth2 (MAS). This endpoint creates the device
        # with no login at all, answering 201 for a new one and 200 for one that
        # already existed.
        #
        # The device id is OURS to choose and must never change afterwards: it
        # is the identity every room key we hold is bound to.
        def create_device(device_id:, display_name: nil)
          body = {}

          if display_name
            body[:display_name] = display_name
          end

          api.devices(device_id).put(body)
        end

        # DELETE /devices/{deviceId}. MSC4190 removed the UIA requirement for
        # appservices, which is what makes this callable unattended.
        def delete_device(device_id:)
          api.devices(device_id).delete
        end

        def devices = api.devices.get

        def device(device_id:) = api.devices(device_id).get

        # POST /register for an appservice-owned user.
        #
        # `inhibit_login` IS MANDATORY, not tidiness: honouring a login would
        # mean issuing an access token, and under OAuth2 the homeserver no
        # longer owns that -- so without it the call fails with
        # M_APPSERVICE_LOGIN_UNSUPPORTED.
        def register_user(username:)
          api.register.post(
            {
              type:          "m.login.application_service",
              username:      username,
              inhibit_login: true,
            },
          )
        end

        # ── Key backup ────────────────────────────────────────────────────────

        # GET /room_keys/version[/{version}] -- the backup's algorithm and
        # auth_data, which carries the public key it was encrypted to.
        def key_backup_version(version: nil)
          if version
            api.room_keys.version(version).get
          else
            api.room_keys.version.get
          end
        end

        # GET /room_keys/keys -- every backed-up session, as
        # rooms -> sessions -> session_data blobs for
        # Protocol::Matrix::KeyBackup to decrypt.
        def room_keys(version:)
          # Plain keys, not the "?"-prefixed form: that convention exists to
          # separate query params from a BODY on POST/PUT, and a GET has no
          # body -- every kwarg is already a query parameter.
          api.room_keys.keys.get(version: version)
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Client::Encryption" do
    # A real Client with its transport stubbed, so these specs exercise the
    # actual path construction AND the OpenAPI path-tree validation -- a wrong
    # path fails here rather than as a 404 from a homeserver.
    def recording_client(response = {})
      # The REAL path tree. Api memoises it process-wide, and the Api specs
      # inject a small fixture tree without restoring it (Api.reset! exists for
      # that and goes uncalled), so without this these specs pass or fail
      # according to the order scampi happens to load files in.
      Async::Matrix::Api.reset!

      config = Async::Matrix::Config.new({
        "homeserver" => {"address" => "http://synapse:8008", "domain" => "example.org"},
        "appservice" => {"as_token" => "as", "hs_token" => "hs", "bot" => {"username" => "bot"}},
      })
      client = Async::Matrix::Client.new(config)
      calls = []
      client.define_singleton_method(:calls) { calls }
      client.define_singleton_method(:request) do |method, path, body = nil, **_options|
        calls << [method, path, body]
        response
      end
      client
    end

    def last(client) = client.calls.last

    # ── Publishing ────────────────────────────────────────────────────────────

    it "uploads device keys" do
      client = recording_client
      client.upload_keys(device_keys: {"user_id" => "@bot:example.org"})

      last(client)[0].should == "POST"
      last(client)[1].should == "/_matrix/client/v3/keys/upload"
      last(client)[2].should == {device_keys: {"user_id" => "@bot:example.org"}}
    end

    it "uploads all three kinds of key together" do
      client = recording_client
      client.upload_keys(
        device_keys: {"a" => 1},
        one_time_keys: {"signed_curve25519:k" => {"key" => "k"}},
        fallback_keys: {"signed_curve25519:f" => {"key" => "f", "fallback" => true}},
      )

      last(client)[2].keys.sort.should == [:device_keys, :fallback_keys, :one_time_keys]
    end

    # A nil is omitted rather than sent as null -- "May be absent if no new
    # one-time keys are required".
    it "omits what it was not given" do
      client = recording_client
      client.upload_keys(one_time_keys: {})

      last(client)[2].should == {}
    end

    it "uploads cross-signing keys" do
      client = recording_client
      client.upload_cross_signing_keys(master_key: {"keys" => {}})

      last(client)[1].should == "/_matrix/client/v3/keys/device_signing/upload"
      last(client)[2].should == {master_key: {"keys" => {}}}
    end

    it "uploads signatures" do
      client = recording_client
      client.upload_signatures({"@bot:example.org" => {"ed25519:DEV" => {}}})

      last(client)[1].should == "/_matrix/client/v3/keys/signatures/upload"
    end

    # ── Querying ──────────────────────────────────────────────────────────────

    # An empty device list per user means "all of their devices".
    it "queries keys for a set of users" do
      client = recording_client
      client.query_keys(user_ids: ["@ada:example.org", "@bob:example.org"])

      last(client)[1].should == "/_matrix/client/v3/keys/query"
      last(client)[2].should == {
        device_keys: {"@ada:example.org" => [], "@bob:example.org" => []},
      }
    end

    it "passes the device_lists token when it has one" do
      client = recording_client
      client.query_keys(user_ids: ["@ada:example.org"], token: "s72")

      last(client)[2][:token].should == "s72"
    end

    it "claims one key per device, naming the algorithm" do
      client = recording_client
      client.claim_keys(devices: {"@ada:example.org" => ["DEV1", "DEV2"]})

      last(client)[1].should == "/_matrix/client/v3/keys/claim"
      last(client)[2].should == {
        one_time_keys: {
          "@ada:example.org" => {
            "DEV1" => "signed_curve25519",
            "DEV2" => "signed_curve25519",
          },
        },
      }
    end

    # ── To-device ─────────────────────────────────────────────────────────────

    it "sends to-device messages with a transaction id" do
      client = recording_client
      client.send_to_device(
        event_type: "m.room.encrypted",
        messages: {"@ada:example.org" => {"DEV1" => {"algorithm" => "m.olm.v1.curve25519-aes-sha2"}}},
      )

      last(client)[0].should == "PUT"
      last(client)[1].should.be.start_with? "/_matrix/client/v3/sendToDevice/m.room.encrypted/"
      last(client)[2].should == {
        messages: {"@ada:example.org" => {"DEV1" => {"algorithm" => "m.olm.v1.curve25519-aes-sha2"}}},
      }
    end

    # Idempotence: a retry after a timeout must not deliver twice.
    it "lets the caller supply the transaction id" do
      client = recording_client
      client.send_to_device(event_type: "m.room.encrypted", messages: {}, txn_id: "txn1")

      last(client)[1].should == "/_matrix/client/v3/sendToDevice/m.room.encrypted/txn1"
    end

    it "generates a different transaction id each time" do
      client = recording_client
      client.send_to_device(event_type: "m.room.encrypted", messages: {})
      client.send_to_device(event_type: "m.room.encrypted", messages: {})

      client.calls[0][1].should.not == client.calls[1][1]
    end

    # ── Devices ───────────────────────────────────────────────────────────────

    # MSC4190: creates the device with no /login, which is the only way under
    # OAuth2.
    it "creates a device" do
      client = recording_client
      client.create_device(device_id: "ABCDEFGHIJ", display_name: "controller")

      last(client)[0].should == "PUT"
      last(client)[1].should == "/_matrix/client/v3/devices/ABCDEFGHIJ"
      last(client)[2].should == {display_name: "controller"}
    end

    it "deletes a device" do
      client = recording_client
      client.delete_device(device_id: "ABCDEFGHIJ")

      last(client)[0].should == "DELETE"
      last(client)[1].should == "/_matrix/client/v3/devices/ABCDEFGHIJ"
    end

    # inhibit_login is mandatory under OAuth2: honouring a login would mean
    # issuing an access token the homeserver no longer owns.
    it "registers an appservice user without logging it in" do
      client = recording_client
      client.register_user(username: "controller")

      last(client)[1].should == "/_matrix/client/v3/register"
      last(client)[2].should == {
        type: "m.login.application_service",
        username: "controller",
        inhibit_login: true,
      }
    end

    # ── Key backup ────────────────────────────────────────────────────────────

    it "reads the current backup version" do
      client = recording_client
      client.key_backup_version

      last(client)[0].should == "GET"
      last(client)[1].should == "/_matrix/client/v3/room_keys/version"
    end

    it "reads a specific backup version" do
      client = recording_client
      client.key_backup_version(version: "3")

      last(client)[1].should == "/_matrix/client/v3/room_keys/version/3"
    end

    it "fetches the backed-up keys for a version" do
      client = recording_client
      client.room_keys(version: "3")

      last(client)[1].should == "/_matrix/client/v3/room_keys/keys?version=3"
    end
  end
