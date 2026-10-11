# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the login token, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::LoginToken}.
          module LoginToken
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # No changes in v1.15.
            module V1_15
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # No changes in v1.12.
            module V1_12
            end

            # No changes in v1.11.
            module V1_11
            end

            # No changes in v1.10.
            module V1_10
            end

            # No changes in v1.9.
            module V1_9
            end

            # No changes in v1.8.
            module V1_8
            end

            # v1.7 added asking for a token to log in with.
            module V1_7
              def self.included(base)
                # The rig accepts any password, so one round of user interactive authentication is enough.
                base.let(:auth){{type: "m.login.password", identifier: {type: "m.id.user", user: self.user_id}, password: Async::Matrix::TEST_PASSWORD}}

                base.it "can generateLoginToken" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  expect(generated.login_token).to be_a(String)
                  expect(generated.expires_in_ms).to be > 0
                end

                # The token logs a user in, which is what it is for.
                base.it "issues a token which logs the user in" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  session = unauthenticated.login(self.user_id, nil, type: "m.login.token", token: generated.login_token)

                  expect(session.user_id).to be == self.user_id
                end

                base.it "is refused without user interactive authentication" do
                  error = nil

                  begin
                    client.login_token.generate_login_token
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.status).to be == 401
                end

                # The challenge names the session and the stages, without which the caller cannot answer it.
                base.it "reports the challenge it was refused with" do
                  challenge = nil

                  begin
                    client.login_token.generate_login_token
                  rescue Async::Matrix::InteractiveAuthenticationError => challenge
                  end

                  expect(challenge).not.to be_nil
                  expect(challenge.session).to be_a(String)
                  expect(challenge.stages).to be(:include?, ["m.login.password"])
                  expect(challenge).to be(:accepts?, "m.login.password")
                end

                # Answering the challenge with the session it named completes the stage.
                base.it "accepts the challenge it reported" do
                  challenge = nil

                  begin
                    client.login_token.generate_login_token
                  rescue Async::Matrix::InteractiveAuthenticationError => challenge
                  end

                  generated = client.login_token.generate_login_token(auth: auth.merge(session: challenge.session))

                  expect(generated.login_token).to be_a(String)
                end

                # The whole point of the token: it logs the user in on another device.
                base.it "issues a token which logs the user in elsewhere" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  elsewhere = unauthenticated.logged_in_with_token(generated.login_token)
                  whoami = elsewhere.get_token_owner

                  expect(whoami.user_id).to be == self.user_id
                  expect(whoami.device_id).not.to be == client.get_token_owner.device_id
                end

                # The login on its own, without deriving a client from it.
                base.it "logs in with the token without deriving a client" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  session = unauthenticated.login_with_token(generated.login_token)

                  expect(session.user_id).to be == self.user_id
                  expect(session.access_token).to be_a(String)
                  expect(session.device_id).to be_a(String)
                end

                # A token is single use, so the second attempt is refused.
                base.it "issues a token which is refused the second time" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  unauthenticated.login_with_token(generated.login_token)

                  expect do
                    unauthenticated.login_with_token(generated.login_token)
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                # A single sign on redirect ends the same way, so the token may be taken from its query.
                base.it "issues a token which can be taken from a redirect" do
                  generated = client.login_token.generate_login_token(auth: auth)

                  elsewhere = unauthenticated.logged_in_with_sso("http://127.0.0.1:9999/cb?loginToken=#{generated.login_token}")

                  expect(elsewhere.get_token_owner.user_id).to be == self.user_id
                end
              end
            end

            # No changes in v1.6.
            module V1_6
            end

            # No changes in v1.5.
            module V1_5
            end

            # No changes in v1.4.
            module V1_4
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("login token cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if LoginToken.const_defined?(name, false)
                  include LoginToken.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
