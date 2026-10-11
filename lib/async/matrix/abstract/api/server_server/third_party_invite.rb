# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::ThirdPartyInvite}.
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
            # Ask the inviting server to turn an invite by address into one by user ID.
            #
            # @parameter room_id [String] the room the invite is to.
            # @parameter event [Hash] the membership event the asking server would like sent.
            # @returns [Representation] the empty answer.
            def exchange_third_party_invite(room_id, event)
              path = "#{FEDERATION_V1}/exchange_third_party_invite/#{::Protocol::URL::Encoding.escape(room_id)}"

              api::Representation.put(@resource.with(path: path), event)
            end

            # Tell a homeserver that an address it invited now belongs to a user.
            #
            # @parameter medium [String] the kind of address, e.g. `email`.
            # @parameter address [String] the address itself.
            # @parameter mxid [String] the user it now belongs to.
            # @parameter invites [Array(Hash)] the invites which were waiting on it.
            # @returns [Representation] the empty answer.
            def on_bind_third_party_identifier(medium, address, mxid, invites)
              path = "#{FEDERATION_V1}/3pid/onbind"
              payload = {medium: medium, address: address, mxid: mxid, invites: invites}

              api::Representation.put(@resource.with(path: path), payload)
            end
          end
        end
      end
    end
  end
end
