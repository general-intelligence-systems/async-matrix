# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::EventAuth}.
        module EventAuth
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

          # v1.1 asked what authorises an event.
          module V1_1
            # The events which authorise an event, so that it can be checked.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event to ask about.
            # @returns [AuthChain] the chain of events which authorise it.
            def get_event_auth(room_id, event_id)
              path = "#{FEDERATION_V1}/event_auth/#{::Protocol::URL::Encoding.escape(room_id)}/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::AuthChain.get(@resource.with(path: path))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::AuthChain}.
        module AuthChain
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

          # v1.1 answered with the chain of events.
          module V1_1
            # The chain reaches back to the creation of the room, which authorises everything.
            #
            # @returns [Array(Hash)] the events which authorise the one asked about.
            def auth_chain
              self.value[:auth_chain] || []
            end

            # @returns [Boolean] whether nothing authorises it, which only an unknown event gives.
            def empty?
              self.auth_chain.empty?
            end

            # @returns [Array(String)] the types of the events in the chain.
            def types
              self.auth_chain.map{|event| event[:type]}
            end
          end
        end
      end
    end
  end
end
