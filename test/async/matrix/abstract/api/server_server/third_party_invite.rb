# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for inviting somebody by an address, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::ThirdPartyInvite}.
          module ThirdPartyInvite
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

            # v1.1 exchanged an address for a membership.
            module V1_1
              def self.included(base)
                base.let(:inviter){client.get_token_owner.user_id}

                # The exchange only means anything where an invite by address is already waiting, which takes an identity server to have issued a token. Nobody is invited here, so the homeserver refuses - which is the answer the specification gives for it.
                base.it "can exchangeThirdPartyInvite" do
                  event = {
                    type: "m.room.member",
                    room_id: room.id,
                    sender: inviter,
                    state_key: outsider,
                    content: {membership: "invite"},
                  }

                  expect do
                    server.third_party_invite.exchange_third_party_invite(room.id, event).value
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                # The specification asks for PUT, and Synapse answers POST: a second backend is how a reading like this is told from a bug.
                base.it "can onBindThirdPartyIdentifier" do
                  expect do
                    server.third_party_invite.on_bind_third_party_identifier("email", "nobody@example.test", user_id, []).value
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("third party invite cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if ThirdPartyInvite.const_defined?(name, false)
                  include ThirdPartyInvite.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
