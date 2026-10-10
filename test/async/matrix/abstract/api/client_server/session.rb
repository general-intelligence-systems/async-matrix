# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# The cases for the session operations, layered by specification version exactly as the
# implementation is: a case lives in the version which introduced the thing it exercises, and the
# version under test decides which layers apply. A case named `can <operationId>` is what
# {Async::Matrix::OperationsContext} requires, and it must reach the homeserver.
#
# `CASES` applies the layers up to the version under test, in the same ascending order the library
# uses, so the concrete test includes one thing rather than knowing about versions at all.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Session
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

            # No changes in v1.7.
            module V1_7
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

            # v1.3 added refresh tokens, which the server only issues when the client asks for one.
            module V1_3
              def self.included(base)
                base.it "reports a refresh token when one is issued" do
                  login = unauthenticated.login(username, Async::Matrix::TEST_PASSWORD, refresh_token: true)

                  expect(login.refresh_token).to be_a(String)
                  expect(login.expires_in_ms).to be_a(Integer)
                end
              end
            end

            # v1.2 added `is_guest` to the whoami response.
            module V1_2
              def self.included(base)
                base.it "reports whether the user is a guest" do
                  expect(client.whoami.guest?).to be == false
                end
              end
            end

            # v1.1 is the oldest version this library supports, and every session operation already
            # exists at it, so it carries the cases for all of them.
            module V1_1
              def self.included(base)
                base.it "can getLoginFlows" do
                  expect(unauthenticated.login_flows.types).to be(:include?, "m.login.password")
                end

                base.it "can login" do
                  expect(unauthenticated.login(username, Async::Matrix::TEST_PASSWORD).user_id).to be == self.user_id
                end

                base.it "can getTokenOwner" do
                  expect(client.whoami.user_id).to be == self.user_id
                end

                base.it "can logout" do
                  # A fresh session, so that logging out does not invalidate the one the suite shares:
                  session = unauthenticated.logged_in("logout-#{SecureRandom.hex(4)}", Async::Matrix::TEST_PASSWORD)

                  expect(session.logout.value).to be_a(Hash)
                end

                base.it "can logout_all" do
                  session = unauthenticated.logged_in("logout-all-#{SecureRandom.hex(4)}", Async::Matrix::TEST_PASSWORD)

                  expect(session.logout_all.value).to be_a(Hash)
                end

                base.it "reports the homeserver the user belongs to" do
                  expect(unauthenticated.login(username, Async::Matrix::TEST_PASSWORD).home_server).to be == "localhost"
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("session cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Session.const_defined?(name, false)
                  include Session.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
