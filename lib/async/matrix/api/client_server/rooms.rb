# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/rooms"

module Async
  module Matrix
    module ClientServer
      # The response to sending an event into a room.
      class SentEvent < Representation
        include Versioned

        # @returns [String] the ID of the event that was sent.
        def event_id
          self.value[:event_id]
        end
      end

      # The response to creating or joining a room.
      class RoomReference < Representation
        include Versioned

        # @returns [String] the ID of the room.
        def room_id
          self.value[:room_id]
        end
      end

      # The state events of a room.
      class State < Representation
        include Versioned

        include Enumerable

        # Enumerate over every state event.
        #
        # @yields {|event| ...}
        #   @parameter event [Hash] the state event.
        def each(&block)
          if block_given?
            self.value.each(&block)
          else
            to_enum
          end
        end

        # Find a single state event.
        #
        # @parameter type [String] the event type, e.g. `m.room.name`.
        # @parameter state_key [String] the state key, which is usually empty.
        # @returns [Hash | nil] the state event, if present.
        def [](type, state_key = "")
          self.find do |event|
            event[:type] == type and event[:state_key] == state_key
          end
        end

        # @returns [String | nil] the name of the room, if it has one.
        def name
          self["m.room.name"]&.dig(:content, :name)
        end

        # @returns [String | nil] the topic of the room, if it has one.
        def topic
          self["m.room.topic"]&.dig(:content, :topic)
        end
      end

      # A page of a room's timeline.
      #
      # Pagination uses opaque tokens: `start` names this page, `finish` is the next `from`.
      class Messages < Representation
        include Versioned

        include Enumerable

        # @returns [Array(Hash)] the events in this page, in the order the server returned them.
        def events
          self.value[:chunk]
        end

        # Enumerate over the events in this page, each wrapped in the envelope its framing calls for. {#events} is the raw form, for anything the event classes do not name.
        #
        # @yields {|event| ...}
        #   @parameter event [Events::Envelope] the event.
        def each(&block)
          if block_given?
            registry = Events.registry(self.version)

            self.events.each do |event|
              yield registry.wrap(event)
            end
          else
            to_enum
          end
        end

        # @returns [Boolean] whether this page is empty.
        def empty?
          self.events.empty?
        end

        # @returns [String] the pagination token for the start of this page.
        def start
          self.value[:start]
        end

        # @returns [String | nil] the pagination token for the following page, if any.
        def finish
          self.value[:end]
        end

        # The following page of events, continuing in the same direction.
        #
        # @returns [Messages | nil] the following page, or nil if this is the last one.
        def following
          if from = self.finish
            self.class.get(@resource.with(parameters: {from: from}))
          else
            nil
          end
        end
      end

      # The members of a room, keyed by user ID.
      class JoinedMembers < Representation
        include Versioned

        # @returns [Hash] the joined members, keyed by user ID.
        def members
          self.value[:joined]
        end

        # @returns [Array(String)] the user IDs of the joined members.
        def user_ids
          self.members.keys.map(&:to_s)
        end
      end

      # The membership events of a room.
      class Members < Representation
        include Versioned
        include Enumerable

        # @returns [Array(Hash)] the membership events.
        def events
          self.value[:chunk]
        end

        # Enumerate over each membership event.
        #
        # @yields {|event| ...}
        # 	@parameter event [Hash] the membership event.
        def each(&block)
          if block_given?
            self.events.each(&block)
          else
            to_enum
          end
        end

        # @returns [Array(String)] the user IDs the events are about.
        def user_ids
          self.events.map{|event| event[:state_key]}
        end
      end

      # A single event from a room's timeline.
      class Event < Representation
        include Versioned

        # @returns [String] the ID of the event.
        def event_id
          self.value[:event_id]
        end

        # @returns [String] the type of the event, e.g. `m.room.message`.
        def type
          self.value[:type]
        end

        # @returns [String] the fully qualified ID of the user who sent the event.
        def sender
          self.value[:sender]
        end

        # @returns [Hash] the content of the event.
        def content
          self.value[:content]
        end
      end

      # A single state event.
      #
      # The endpoint returns the content alone by default, and the whole event when asked for `format: "event"`, so {#content} answers for both shapes.
      class StateEvent < Representation
        include Versioned

        # @returns [Hash] the content of the state event.
        def content
          self.value[:content] || self.value
        end
      end

      # A resource with no representation of its own.
      #
      # There is no `GET /rooms/{roomId}`, only its state, timeline and membership, so it carries its own identifier.
      class Room
        include Versioned

        # The default number of events to fetch per page of timeline.
        DEFAULT_LIMIT = 10

        # Construct a room below the given resource.
        #
        # @parameter parent [Async::REST::Resource] the resource to derive from, typically a {Client}.
        # @parameter id [String] the room ID, e.g. `!abc:localhost`.
        # @returns [Room] the room.
        def self.for(parent, id)
          self.new(parent.with(path: self.path_for(id)), id)
        end

        # The absolute path of a room, which replaces the path it derives from.
        #
        # @parameter id [String] the room ID or alias.
        # @returns [String] the path.
        def self.path_for(id)
          "#{V3}/rooms/#{::Protocol::URL::Encoding.escape(id)}"
        end

        # @returns [String] a transaction ID, used to make sending an event idempotent.
        def self.transaction_id
          SecureRandom.uuid
        end

        # @parameter resource [Async::REST::Resource] the resource for this room.
        # @parameter id [String] the room ID.
        def initialize(resource, id)
          @resource = resource
          @id = id
        end

        # @attribute [Async::REST::Resource] the resource for this room.
        attr :resource

        # @attribute [String] the room ID.
        attr :id

        def inspect
          "\#<#{self.class} #{@id}>"
        end

        alias to_s id

        # @returns [State] the current state of the room.
        def get_room_state
          api::State.get(@resource.with(path: "state"))
        end

        # @returns [JoinedMembers] the members currently joined to the room.
        def get_joined_members_by_room
          api::JoinedMembers.get(@resource.with(path: "joined_members"))
        end

        # A page of the room's timeline.
        #
        # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
        # @parameter limit [Integer] the maximum number of events to return.
        # @parameter from [String | nil] the pagination token to start from.
        # @returns [Messages] the page of events.
        def get_room_events(dir: "b", limit: DEFAULT_LIMIT, from: nil, **parameters)
          if from.nil? and self.pagination_requires_from?
            raise ArgumentError, "A from token is required before v1.3!"
          end

          parameters[:dir] = dir
          parameters[:limit] = limit
          if from
            parameters[:from] = from
          end

          api::Messages.get(@resource.with(path: "messages", parameters: parameters))
        end

        # Send a message event into the room, which is any event the timeline carries rather than state.
        #
        # @parameter type [String] the event type, e.g. `m.room.message`.
        # @parameter content [Hash] the event content.
        # @parameter transaction_id [String] a unique ID which makes this request idempotent.
        # @returns [SentEvent] the sent event.
        def send_message(type, content, transaction_id: self.class.transaction_id)
          path = "send/#{::Protocol::URL::Encoding.escape(type)}/#{::Protocol::URL::Encoding.escape(transaction_id)}"

          api::SentEvent.put(@resource.with(path: path), content)
        end

        # Join this room.
        #
        # @parameter via [Array(String) | nil] the servers to attempt the join through.
        # @returns [RoomReference] the joined room.
        def join_room_by_id(via: nil, **payload)
          parameters = {self.join_via_parameter => via}.compact

          api::RoomReference.post(@resource.with(path: "join", parameters: parameters), payload)
        end

        # Leave this room.
        #
        # @parameter payload [Hash] the fields to send, such as a reason.
        # @returns [Representation] the empty response.
        def leave_room(**payload)
          api::Representation.post(@resource.with(path: "leave"), payload)
        end

        # Forget this room, which requires having left it first.
        #
        # @parameter payload [Hash] the fields to send.
        # @returns [Representation] the empty response.
        def forget_room(**payload)
          api::Representation.post(@resource.with(path: "forget"), payload)
        end

        # The members of this room.
        #
        # @parameter at [String | nil] a sync token, to read the membership as it was then.
        # @parameter membership [String | nil] only include members in this membership state.
        # @parameter not_membership [String | nil] exclude members in this membership state.
        # @returns [Members] the membership events.
        def get_members_by_room(at: nil, membership: nil, not_membership: nil)
          parameters = {at: at, membership: membership, not_membership: not_membership}.compact

          api::Members.get(@resource.with(path: "members", parameters: parameters))
        end

        # A single event from this room.
        #
        # @parameter event_id [String] the ID of the event.
        # @returns [Event] the event.
        def get_one_room_event(event_id)
          path = "event/#{::Protocol::URL::Encoding.escape(event_id)}"

          api::Event.get(@resource.with(path: path))
        end

        # A single state event from this room.
        #
        # @parameter type [String] the event type, e.g. `m.room.name`.
        # @parameter state_key [String] the state key, which is usually empty.
        # @parameter format [String | nil] `content` for the content alone, `event` for the event.
        # @returns [StateEvent] the state event.
        def get_room_state_with_key(type, state_key = "", format: nil)
          parameters = {format: format}.compact

          api::StateEvent.get(@resource.with(path: self.state_path(type, state_key), parameters: parameters))
        end

        # Set a state event in this room.
        #
        # @parameter type [String] the event type, e.g. `m.room.name`.
        # @parameter content [Hash] the content of the state event.
        # @parameter state_key [String] the state key, which is usually empty.
        # @returns [SentEvent] the sent event.
        def set_room_state_with_key(type, content, state_key = "")
          api::SentEvent.put(@resource.with(path: self.state_path(type, state_key)), content)
        end

        # Whether paging requires a `from` token, as it did before v1.3.
        #
        # @returns [Boolean] whether `from` is required.
        def pagination_requires_from?
          false
        end

        # The parameter naming the servers to join through.
        #
        # @returns [Symbol] the parameter name.
        def join_via_parameter
          :via
        end

        def close
          @resource.close
        end

        private

        # The path of one state event, trailing slash and all.
        #
        # @parameter type [String] the event type.
        # @parameter state_key [String] the state key, which is usually empty.
        # @returns [String] the path.
        def state_path(type, state_key)
          "state/#{::Protocol::URL::Encoding.escape(type)}/#{::Protocol::URL::Encoding.escape(state_key)}"
        end
      end

      # The rooms the authenticated user has joined.
      class JoinedRooms < Representation
        include Versioned

        include Enumerable

        # @returns [Array(String)] the IDs of the joined rooms.
        def ids
          self.value[:joined_rooms]
        end

        # Enumerate over each joined room.
        #
        # @yields {|room| ...}
        #   @parameter room [Room] the room.
        def each
          if block_given?
            self.ids.each do |id|
              yield api::Room.for(@resource, id)
            end
          else
            to_enum
          end
        end

        # @returns [Boolean] whether the user has joined any rooms.
        def empty?
          self.ids.empty?
        end

        # @parameter id [String] the room ID.
        # @returns [Boolean] whether the user has joined the given room.
        def include?(id)
          self.ids.include?(id)
        end
      end
    end
  end
end
