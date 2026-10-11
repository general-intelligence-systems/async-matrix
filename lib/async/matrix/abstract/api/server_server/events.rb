# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::Events}.
        module Events
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

          # v1.6 found the event nearest a time.
          module V1_6
            # The event nearest a time, in one direction.
            #
            # @parameter room_id [String] the room to search.
            # @parameter ts [Integer] the time to search from, in milliseconds since the epoch.
            # @parameter dir [String] `f` for the first event after, `b` for the last before.
            # @returns [EventAtTimestamp] the event, and when it was sent.
            def get_event_by_timestamp(room_id, ts, dir)
              path = "#{FEDERATION_V1}/timestamp_to_event/#{::Protocol::URL::Encoding.escape(room_id)}"

              api::EventAtTimestamp.get(@resource.with(path: path, parameters: {ts: ts, dir: dir}))
            end
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

          # v1.1 read an event and the state around it.
          module V1_1
            # One event, as the server which has it reports it.
            #
            # @parameter event_id [String] the event to ask for.
            # @returns [EventTransaction] a transaction carrying that one event.
            def get_event(event_id)
              path = "#{FEDERATION_V1}/event/#{::Protocol::URL::Encoding.escape(event_id)}"

              api::EventTransaction.get(@resource.with(path: path))
            end

            # The state of a room at an event, as whole events.
            #
            # @parameter room_id [String] the room to read.
            # @parameter event_id [String] the event to read the state at.
            # @returns [RoomState] the state, and what authorises it.
            def get_room_state(room_id, event_id)
              path = "#{FEDERATION_V1}/state/#{::Protocol::URL::Encoding.escape(room_id)}"

              api::RoomState.get(@resource.with(path: path, parameters: {event_id: event_id}))
            end

            # The state of a room at an event, as IDs rather than events.
            #
            # @parameter room_id [String] the room to read.
            # @parameter event_id [String] the event to read the state at.
            # @returns [RoomStateIds] the IDs of the state, and of what authorises it.
            def get_room_state_ids(room_id, event_id)
              path = "#{FEDERATION_V1}/state_ids/#{::Protocol::URL::Encoding.escape(room_id)}"

              api::RoomStateIds.get(@resource.with(path: path, parameters: {event_id: event_id}))
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::EventTransaction}.
        module EventTransaction
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

          # v1.1 answered with events in a transaction.
          module V1_1
            # @returns [String | nil] the server which sent the transaction.
            def origin
              self.value[:origin]
            end

            # @returns [Integer | nil] when it was sent, in milliseconds since the epoch.
            def origin_server_ts
              self.value[:origin_server_ts]
            end

            # The specification calls a room event a PDU, which is what a transaction carries.
            #
            # @returns [Array(Hash)] the events.
            def pdus
              self.value[:pdus] || []
            end

            # @returns [Hash | nil] the first event, where there is one.
            def first
              self.pdus.first
            end

            # @returns [Boolean] whether the transaction carries no events.
            def empty?
              self.pdus.empty?
            end

            # An event has carried no ID of its own since room version 3, so it is read by type.
            #
            # @returns [Array(String)] the types of the events.
            def types
              self.pdus.map{|pdu| pdu[:type]}
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::RoomState}.
        module RoomState
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

          # v1.1 answered with the state and its auth chain.
          module V1_1
            # @returns [Array(Hash)] the state events of the room at that event.
            def pdus
              self.value[:pdus] || []
            end

            # Every event the state events depend on, so the state can be checked without asking again.
            #
            # @returns [Array(Hash)] the events which authorise the state.
            def auth_chain
              self.value[:auth_chain] || []
            end

            # @returns [Boolean] whether the room has no state, which a real room never does.
            def empty?
              self.pdus.empty?
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::RoomStateIds}.
        module RoomStateIds
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

          # v1.1 answered with IDs rather than events.
          module V1_1
            # @returns [Array(String)] the IDs of the state events.
            def pdu_ids
              self.value[:pdu_ids] || []
            end

            # @returns [Array(String)] the IDs of the events which authorise the state.
            def auth_chain_ids
              self.value[:auth_chain_ids] || []
            end

            # @returns [Boolean] whether the room has no state.
            def empty?
              self.pdu_ids.empty?
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::EventAtTimestamp}.
        module EventAtTimestamp
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

          # v1.6 answered with the event nearest a time.
          module V1_6
            # @returns [String | nil] the event which was nearest.
            def event_id
              self.value[:event_id]
            end

            # @returns [Integer | nil] when it was sent, in milliseconds since the epoch.
            def origin_server_ts
              self.value[:origin_server_ts]
            end
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
