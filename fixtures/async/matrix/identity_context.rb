# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

require "sus/fixtures/async"

require "async/matrix"

require_relative "client_context"

module Async
  module Matrix
    # Where the identity server is.
    #
    # The rig runs sydent, which `bin/test --api identity` brings up beside the homeserver.
    IDENTITY_SERVER = ENV.fetch("MATRIX_IDENTITY_SERVER", "http://localhost:7302")

    # Included by a test which exercises the identity service API.
    #
    # An identity server has no accounts of its own: a user proves who they are with an OpenID token from their homeserver, which the identity server verifies by asking that homeserver over federation. So a test which needs an account logs in, asks for a token, and exchanges it here.
    #
    # The client is called `unauthenticated` because that is the name {OperationsContext} spies on to prove a case made a request.
    IdentityContext = Sus::Shared("an identity client") do
      include Sus::Fixtures::Async::ReactorContext

      let(:unauthenticated) {Async::Matrix::Identity::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::IDENTITY_SERVER)}

      # A fresh user of the homeserver, since an account here is a user of one.
      let(:username) {"identity-#{SecureRandom.hex(6)}"}

      let(:user_id) {"@#{self.username}:localhost"}

      let(:homeserver) {Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::HOMESERVER)}

      let(:logged_in) {homeserver.logged_in(self.username, Async::Matrix::TEST_PASSWORD)}

      # The token the homeserver issues to prove who this user is.
      let(:openid) {logged_in.openid.request_open_id_token(self.user_id)}

      # The identity server's own token, which the OpenID token was exchanged for.
      let(:registered) {unauthenticated.v2_auth.register_account(openid.access_token, openid.token_type, openid.matrix_server_name, openid.expires_in)}

      # The version of the policies the server asks for, which it names itself.
      let(:terms) {unauthenticated.v2_terms.get_terms.policies[:terms_of_service][:en][:url]}

      # A client with an account, whose terms are signed.
      #
      # Sydent answers every other authenticated operation `M_TERMS_NOT_SIGNED` until they are, so signing them is part of having an account rather than a case of its own.
      let(:identity) do
        session = unauthenticated.authenticated(registered.token)
        session.v2_terms.agree_to_terms([terms])

        session
      end
    end
  end
end
