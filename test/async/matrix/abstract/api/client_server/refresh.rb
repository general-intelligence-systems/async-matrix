# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the refresh operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module Refresh
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

            # v1.3 added the refresh endpoint.
            module V1_3
              def self.included(base)
                base.it "can refresh" do
                  refreshed = unauthenticated.refresh.refresh(login.refresh_token)

                  expect(refreshed.access_token).to be_a(String)
                end

                base.it "issues a token which authenticates a request" do
                  refreshed = unauthenticated.refresh.refresh(login.refresh_token)

                  session = unauthenticated.authenticated(refreshed.access_token)

                  expect(session.get_token_owner.user_id).to be == self.user_id
                end

                # The homeserver rotates the refresh token, so the next renewal uses the new one.
                base.it "rotates the refresh token" do
                  refreshed = unauthenticated.refresh.refresh(login.refresh_token)

                  expect(refreshed.refresh_token).to be_a(String)
                  expect(refreshed.refresh_token).not.to be == login.refresh_token
                end

                base.it "reports how long the new access token lasts" do
                  expect(unauthenticated.refresh.refresh(login.refresh_token).expires_in_ms).to be > 0
                end

                base.it "fails with a refresh token the homeserver does not know" do
                  error = nil

                  begin
                    unauthenticated.refresh.refresh("syr_not_a_real_token")
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error).to be_a(Async::Matrix::RequestError)
                  expect(error).to be(:unknown_token?)
                end

                base.it "replaces a rejected access token and makes the request again" do
                  session = unauthenticated.authenticated("syt_not_a_real_token", refresh_token: login.refresh_token)

                  expect(session.get_token_owner.user_id).to be == self.user_id
                  expect(session.delegate.credentials.generation).to be == 1
                end

                # A write has a body, which has already been read in order to send it once.
                base.it "replays the body of a write" do
                  session = unauthenticated.authenticated("syt_not_a_real_token", refresh_token: login.refresh_token)

                  expect(session.create_room(name: Async::Matrix::TEST_ROOM_NAME).id).to be =~ /\A!/
                end

                base.it "renews once however many requests are in flight" do
                  session = unauthenticated.authenticated("syt_not_a_real_token", refresh_token: login.refresh_token)

                  # Resolved before the tasks start: a `let` is not fiber safe.
                  credentials = session.delegate.credentials

                  owners = 8.times.map{Async{session.get_token_owner.user_id}}.map(&:wait)

                  expect(owners.uniq).to be == [self.user_id]
                  expect(credentials.generation).to be == 1
                end

                base.it "derives a logged in client which can renew its own access token" do
                  credentials = client.delegate.credentials

                  expect(credentials).to be(:renewable?)
                  expect(credentials.expires_at).to be_a(Time)
                end
              end
            end

            # No changes in v1.2.
            module V1_2
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("refresh cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Refresh.const_defined?(name, false)
                  include Refresh.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
