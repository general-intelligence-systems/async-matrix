# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Relations}.
        module Relations
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

          # v1.10 added recursing into a thread's own relations.
          module V1_10
            # The events which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter recurse [Boolean | nil] whether to also return events relating to the related events.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events(room_id, event_id, dir: "b", recurse: nil, from: nil, to: nil, limit: nil)
              api::RelatedEvents.get(@resource.with(path: self.relations_path_for(room_id, event_id), parameters: self.relations_parameters(from, to, limit, dir: dir, recurse: recurse)))
            end

            # The events of one relation type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter recurse [Boolean | nil] whether to also return events relating to the related events.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type(room_id, event_id, rel_type, dir: "b", recurse: nil, from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit, dir: dir, recurse: recurse)))
            end

            # The events of one relation type and one event type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter event_type [String] the event type, e.g. `m.room.message`.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter recurse [Boolean | nil] whether to also return events relating to the related events.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type_and_event_type(room_id, event_id, rel_type, event_type, dir: "b", recurse: nil, from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}/#{::Protocol::URL::Encoding.escape(event_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit, dir: dir, recurse: recurse)))
            end

            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter recurse [Boolean | nil] whether to also return events relating to the related events.
            # @returns [Hash] the parameters all three take.
            def relations_parameters(from, to, limit, dir: "b", recurse: nil)
              super(from, to, limit, dir: dir).merge(recurse: recurse).compact
            end
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

          # v1.4 added paging direction.
          module V1_4
            # The events which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events(room_id, event_id, dir: "b", from: nil, to: nil, limit: nil)
              api::RelatedEvents.get(@resource.with(path: self.relations_path_for(room_id, event_id), parameters: self.relations_parameters(from, to, limit, dir: dir)))
            end

            # The events of one relation type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type(room_id, event_id, rel_type, dir: "b", from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit, dir: dir)))
            end

            # The events of one relation type and one event type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter event_type [String] the event type, e.g. `m.room.message`.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type_and_event_type(room_id, event_id, rel_type, event_type, dir: "b", from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}/#{::Protocol::URL::Encoding.escape(event_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit, dir: dir)))
            end

            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
            # @returns [Hash] the parameters all three take.
            def relations_parameters(from, to, limit, dir: "b")
              super(from, to, limit).merge(dir: dir)
            end
          end

          # v1.3 added reading the events which relate to an event.
          module V1_3
            # The events which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events(room_id, event_id, from: nil, to: nil, limit: nil)
              api::RelatedEvents.get(@resource.with(path: self.relations_path_for(room_id, event_id), parameters: self.relations_parameters(from, to, limit)))
            end

            # The events of one relation type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type(room_id, event_id, rel_type, from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit)))
            end

            # The events of one relation type and one event type which relate to an event.
            #
            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event they relate to.
            # @parameter rel_type [String] the relation, e.g. `m.thread`.
            # @parameter event_type [String] the event type, e.g. `m.room.message`.
            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [RelatedEvents] the page of events.
            def get_relating_events_with_rel_type_and_event_type(room_id, event_id, rel_type, event_type, from: nil, to: nil, limit: nil)
              path = "#{self.relations_path_for(room_id, event_id)}/#{::Protocol::URL::Encoding.escape(rel_type)}/#{::Protocol::URL::Encoding.escape(event_type)}"

              api::RelatedEvents.get(@resource.with(path: path, parameters: self.relations_parameters(from, to, limit)))
            end

            # @parameter room_id [String] the room the event is in.
            # @parameter event_id [String] the event the relations are to.
            # @returns [String] the path of those relations.
            def relations_path_for(room_id, event_id)
              "#{V1}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/relations/#{::Protocol::URL::Encoding.escape(event_id)}"
            end

            # @parameter from [String | nil] the token a previous page ended at.
            # @parameter to [String | nil] the token to stop at.
            # @parameter limit [Integer | nil] the most events wanted.
            # @returns [Hash] the parameters all three take.
            def relations_parameters(from, to, limit)
              {from: from, to: to, limit: limit}.compact
            end
          end

          # No changes in v1.2.
          module V1_2
          end

          # No changes in v1.1.
          module V1_1
          end
        end

        # Layers for {ruby Async::Matrix::ClientServer::RelatedEvents}.
        module RelatedEvents
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

          # v1.10 added how deep a recursive page of relations went.
          module V1_10
            # @returns [Integer | nil] how deep recursion went, if `recurse` was given.
            def recursion_depth
              self.value[:recursion_depth]
            end
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

          # v1.3 added the relations, which page through the events.
          module V1_3
            # @returns [Array(Hash)] the events in this page.
            def chunk
              self.value[:chunk] || []
            end

            # @returns [String | nil] the token to ask for the following page from.
            def next_batch
              self.value[:next_batch]
            end

            # @returns [String | nil] the token to ask for the preceding page from.
            def prev_batch
              self.value[:prev_batch]
            end

            # @returns [Boolean] whether this page is empty.
            def empty?
              self.chunk.empty?
            end
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
