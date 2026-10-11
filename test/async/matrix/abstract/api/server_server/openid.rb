# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for who an OpenID token belongs to, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::OpenID}.
          module OpenID
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

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 exchanged a token for the user it belongs to.
            module V1_1
              def self.included(base)
                # The token comes from the client-server API: a user asks their own homeserver for one, and hands it to a service, which asks the homeserver who it belongs to.
                base.let(:access_token){client.openid.request_open_id_token(user_id).access_token}

                base.it "can exchangeOpenIdToken" do
                  expect(unauthenticated.openid.exchange_open_id_token(access_token).sub).to be == user_id
                end

                base.it "answers the same user under the name Matrix uses" do
                  expect(unauthenticated.openid.exchange_open_id_token(access_token).user_id).to be == user_id
                end

                base.it "refuses a token nobody issued" do
                  expect do
                    unauthenticated.openid.exchange_open_id_token("not-a-token")
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("openid cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if OpenID.const_defined?(name, false)
                  include OpenID.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
