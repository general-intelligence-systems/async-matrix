# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/typing"

module Async
  module Matrix
    module ClientServer
      # Says that this user is typing.
      class Typing
        include Versioned

        # @parameter room_id [String] the room the user is typing in.
        # @parameter user_id [String] the user who is typing.
        # @returns [String] the path of that user's typing state in that room.
        def self.path_for(room_id, user_id)
          "#{V3}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}/typing/#{::Protocol::URL::Encoding.escape(user_id)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Typing] the typing state.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Say whether a user is typing in a room.
        #
        # The homeserver forgets after the timeout, so a client still typing says so again.
        #
        # @parameter room_id [String] the room the user is typing in.
        # @parameter user_id [String] the user who is typing.
        # @parameter typing [Boolean] whether they are typing.
        # @parameter timeout [Integer | nil] how long to say so for, in milliseconds.
        # @returns [Representation] the homeserver's acknowledgement.
        def set_typing(room_id, user_id, typing, timeout: nil)
          payload = {typing: typing, timeout: timeout}.compact

          api::Representation.put(@resource.with(path: self.class.path_for(room_id, user_id)), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
