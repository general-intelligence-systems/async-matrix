# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/knocking"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Knocking on a room, which asks to be let in.
      class Knocking
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Knocking] the knocks.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Knock on a room, which asks its members to invite you.
        #
        # @parameter room_id_or_alias [String] the room to knock on, by ID or by alias.
        # @parameter server_name [Array(String) | nil] the servers to knock through.
        # @parameter reason [String | nil] what to record as the reason.
        # @returns [RoomReference] the room knocked on.
        def knock_room(room_id_or_alias, server_name: nil, reason: nil)
          payload = {reason: reason}.compact
          parameters = {server_name: server_name}.compact

          api::RoomReference.post(@resource.with(path: "#{V3}/knock/#{::Protocol::URL::Encoding.escape(room_id_or_alias)}", parameters: parameters), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
