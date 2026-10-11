# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "sus/fixtures/async/reactor_context"

require "async/matrix"

module Async
  module Matrix
    # The homeserver to test against. The rig in `synapse/` provides one, with rate limiting disabled and a module which registers a user on first login.
    HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:7300")

    # The homeserver which delegates authentication to matrix-authentication-service. The rig in `synapse/` runs one behind the `client-server` compose profile, which binds its own port so it may run alongside a version.
    #
    # Empty where the backend's rig runs none, which is how a rig says the OAuth 2.0 flow cannot be tested against it: see `tuwunel/test.env`, and the tests which need one are left out of the run.
    OAUTH_HOMESERVER = ENV.fetch("MATRIX_OAUTH_HOMESERVER", "http://localhost:7310")

    # The specification version under test. `bin/test` runs the suite once per version, against a server which implements that version. Deliberately not `VERSION`, which is the gem's own.
    TEST_VERSION = ENV.fetch("MATRIX_VERSION", LATEST)

    # The homeserver implementation under test, which is the name of the directory its rig lives in.
    TEST_BACKEND = ENV.fetch("MATRIX_BACKEND", "synapse")

    # How the suite gets an account, which is the one thing the two rigs cannot do the same way.
    #
    # `login` is the `synapse/` rig, whose module registers a user on first login, so logging in is enough and registration stays closed. `register` is the `tuwunel/` rig: tuwunel has no way to accept any password, so that rig opens registration instead and the account is registered before it is logged into. `bin/test` sets this from the backend.
    TEST_ACCOUNTS = ENV.fetch("MATRIX_ACCOUNTS", "login")

    TEST_PASSWORD = "password"

    TEST_ROOM_NAME = "Test Room"

    TEST_ROOM_TOPIC = "Testing async-matrix"

    ClientContext = Sus::Shared("a matrix client") do
      include Sus::Fixtures::Async::ReactorContext

      let(:unauthenticated) {Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::HOMESERVER)}

      # A fresh user and room for each test, so that tests cannot interfere with each other. The rig registers a user on first login, so this needs no setup.
      let(:username) {"test-#{SecureRandom.hex(6)}"}

      let(:user_id) {"@#{self.username}:localhost"}

      let(:client) {self.account(self.username)}

      let(:room) {client.create_room(name: Async::Matrix::TEST_ROOM_NAME, topic: Async::Matrix::TEST_ROOM_TOPIC)}

      # An authenticated client for a user of this name, registering the account where the rig needs asking.
      #
      # A case which needs the homeserver to reject the token asks for one nothing can replace.
      #
      # `logged_in` asks for a refresh token from v1.3, and a homeserver may leave a refreshable access token working after the logout which revoked its refresh token, which leaves such a case with nothing to assert.
      #
      # @parameter username [String] the localpart to be.
      # @parameter through [Client] the unauthenticated client to log in through.
      # @parameter refreshable [Boolean] whether the session may renew its own access token.
      # @returns [Client] a client authenticated as that user.
      def account(username, through: self.unauthenticated, refreshable: true)
        if Async::Matrix::TEST_ACCOUNTS == "register"
          # One round of user interactive authentication, which is all an open registration asks for. `inhibit_login` leaves the account without a device, so the login below is what makes one, and the login is what every case sees: a case watching its own client watches `through`, not this.
          begin
            unauthenticated.registration.register(username: username, password: Async::Matrix::TEST_PASSWORD, auth: {type: "m.login.dummy"}, inhibit_login: true)
          rescue Async::Matrix::RequestError => error
            # A case which asks for the same user twice wants a second device on the one account, not a second account, which is how the rig that registers on first login behaves too.
            unless error.errcode == "M_USER_IN_USE"
              raise
            end
          end
        end

        if refreshable
          through.logged_in(username, Async::Matrix::TEST_PASSWORD)
        else
          login = through.login(username, Async::Matrix::TEST_PASSWORD)

          through.authenticated(login.access_token)
        end
      end

      # Sync until the cursor is current, so a long poll is woken rather than returning at once.
      #
      # @returns [Sync] the first batch which reports nothing new.
      def current_sync
        batches = Enumerator.produce(client.sync(timeout: 0)){|sync| sync.following(timeout: 0)}

        batches.find(&:empty?)
      end

      # Sync until a message with the given body arrives, or give up.
      #
      # A write is not visible to `/sync` the instant it completes, so a test waits for it.
      #
      # @parameter body [String] the body to wait for.
      # @parameter attempts [Integer] how many batches to read.
      # @parameter timeout [Integer] how long each batch may wait, in milliseconds.
      # @returns [Sync | nil] the batch which carried it, or nil.
      def sync_until_message(body, attempts: 5, timeout: 2000)
        batches = Enumerator.produce(client.sync(timeout: 0)){|sync| sync.following(timeout: timeout)}

        # Lazily, so that finding it early does not ask for the batches after it:
        batches.lazy.take(attempts).find do |sync|
          sync.each_message.any?{|message| message.content.body == body}
        end
      end

      after do
        # Every resource and representation shares the client's connection, so closing the root closes all of them:
        @unauthenticated&.close
      end
    end
  end
end
