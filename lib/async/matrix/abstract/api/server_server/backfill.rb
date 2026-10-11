# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module Abstract
      module ServerServer
        # Layers for {ruby Async::Matrix::ServerServer::Backfill}.
        module Backfill
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

          # v1.1 asked for the events before the ones we have.
          module V1_1
            # The events before the ones given, which is how a server fills in history.
            #
            # @parameter room_id [String] the room to read.
            # @parameter event_ids [Array(String)] the events to work backwards from.
            # @parameter limit [Integer] the most events wanted.
            # @returns [EventTransaction] the events, oldest last.
            def backfill_room(room_id, event_ids, limit: 10)
              query = api::Parameters.query(repeated: {v: event_ids}, single: {limit: limit})
              path = api::Parameters.path("#{FEDERATION_V1}/backfill/#{::Protocol::URL::Encoding.escape(room_id)}", query)

              api::EventTransaction.get(@resource.with(path: path))
            end

            # The events between what we have and what we were told about.
            #
            # @parameter room_id [String] the room to read.
            # @parameter earliest_events [Array(String)] the events we already have.
            # @parameter latest_events [Array(String)] the events we are missing the parents of.
            # @parameter limit [Integer | nil] the most events wanted.
            # @parameter min_depth [Integer | nil] how far back to go.
            # @returns [MissingEvents] the events in between.
            def get_missing_previous_events(room_id, earliest_events, latest_events, limit: nil, min_depth: nil)
              path = "#{FEDERATION_V1}/get_missing_events/#{::Protocol::URL::Encoding.escape(room_id)}"
              payload = {earliest_events: earliest_events, latest_events: latest_events, limit: limit, min_depth: min_depth}.compact

              api::MissingEvents.post(@resource.with(path: path), payload)
            end
          end
        end

        # Layers for {ruby Async::Matrix::ServerServer::MissingEvents}.
        module MissingEvents
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

          # v1.1 answered with the events in between.
          module V1_1
            # @returns [Array(Hash)] the events which were missing.
            def events
              self.value[:events] || []
            end

            # @returns [Boolean] whether nothing was missing.
            def empty?
              self.events.empty?
            end

            # An event has carried no ID of its own since room version 3, so it is read by type.
            #
            # @returns [Array(String)] the types of the events.
            def types
              self.events.map{|event| event[:type]}
            end
          end
        end
      end
    end
  end
end
