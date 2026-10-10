# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "protocol/url/encoding"

require_relative "paths"
require_relative "representation"
require_relative "versioned"
require_relative "abstract/rooms"

module Async
  module Matrix
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
        return to_enum unless block_given?

        self.value.each(&block)
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

    # A page of events from a room's timeline.
    #
    # Matrix paginates the timeline with opaque tokens: `start` is the token for the page itself,
    # and `finish` is the token to pass as `from` in order to fetch the following page.
    class Messages < Representation
      include Versioned

      include Enumerable

      # @returns [Array(Hash)] the events in this page, in the order the server returned them.
      def events
        self.value[:chunk]
      end

      # Enumerate over the events in this page.
      #
      # @yields {|event| ...}
      #   @parameter event [Hash] the event.
      def each(&block)
        return to_enum unless block_given?

        self.events.each(&block)
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
        return nil unless from = self.finish

        # The resource already carries `dir` and `limit`, and parameters are merged:
        self.class.get(@resource.with(parameters: {from: from}))
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

    # A room is a resource which has no representation of its own: the client-server API has no
    # `GET /rooms/{roomId}`, only representations of its state, timeline and membership. A room is
    # therefore a navigator which carries its own identifier, because the identifier cannot be
    # recovered from a derived resource.
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

      # The absolute path of a room. The path is absolute so that it replaces, rather than extends,
      # the path of whichever resource it is derived from.
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
      def state
        api::State.get(@resource.with(path: "state"))
      end

      # @returns [JoinedMembers] the members currently joined to the room.
      def joined_members
        api::JoinedMembers.get(@resource.with(path: "joined_members"))
      end

      # A page of the room's timeline.
      #
      # @parameter dir [String] the direction to page in: `b` (backwards) or `f` (forwards).
      # @parameter limit [Integer] the maximum number of events to return.
      # @parameter from [String | nil] the pagination token to start from.
      # @returns [Messages] the page of events.
      def messages(dir: "b", limit: DEFAULT_LIMIT, from: nil, **parameters)
        parameters[:dir] = dir
        parameters[:limit] = limit
        parameters[:from] = from if from

        api::Messages.get(@resource.with(path: "messages", parameters: parameters))
      end

      # Send an event into the room.
      #
      # @parameter type [String] the event type, e.g. `m.room.message`.
      # @parameter content [Hash] the event content.
      # @parameter transaction_id [String] a unique ID which makes this request idempotent.
      # @returns [SentEvent] the sent event.
      def send_event(type, content, transaction_id: self.class.transaction_id)
        path = "send/#{::Protocol::URL::Encoding.escape(type)}/#{::Protocol::URL::Encoding.escape(transaction_id)}"

        api::SentEvent.put(@resource.with(path: path), content)
      end

      # Send a message into the room.
      #
      # @parameter body [String] the message body.
      # @parameter msgtype [String] the message type, e.g. `m.text`.
      # @returns [SentEvent] the sent event.
      def send_message(body, msgtype: "m.text", **content)
        content[:msgtype] = msgtype
        content[:body] = body

        self.send_event("m.room.message", content)
      end

      # Join this room.
      #
      # @returns [RoomReference] the joined room.
      def join(**payload)
        api::RoomReference.post(@resource.with(path: "join"), payload)
      end

      # Leave this room.
      def leave(**payload)
        api::Representation.post(@resource.with(path: "leave"), payload)
      end

      # Forget this room, which requires having left it first.
      def forget(**payload)
        api::Representation.post(@resource.with(path: "forget"), payload)
      end

      def close
        @resource.close
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
        return to_enum unless block_given?

        self.ids.each do |id|
          yield api::Room.for(@resource, id)
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
