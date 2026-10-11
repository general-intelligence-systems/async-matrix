# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::RoomPolicy}.
        module RoomPolicy
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 added the policy server a room may name.
          module V1_18
            # Ask a policy server to recommend an event for the room.
            #
            # @parameter event [Hash] the event to have signed.
            # @returns [SignedEvent] the event, signed by the policy server.
            def ask_policy_server_to_sign(event)
              api::SignedEvent.post(@resource.with(path: "#{POLICY_V1}/sign"), event)
            end
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

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::SignedEvent}.
        module SignedEvent
          # No changes in v1.19.
          module V1_19
          end

          # v1.18 answered with the event it signed.
          module V1_18
            # A signature is the policy server saying it recommends the event for the room.
            #
            # @returns [Hash] the signatures, by server name.
            def signatures
              self.value[:signatures] || {}
            end

            # Whether a policy server has signed the event.
            #
            # @parameter server_name [String] the server to look for.
            # @returns [Boolean] whether it signed.
            def signed_by?(server_name)
              self.signatures.key?(server_name.to_sym)
            end
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

          # No changes in v1.1.
          module V1_1
          end
        end
      end
    end
  end
end
