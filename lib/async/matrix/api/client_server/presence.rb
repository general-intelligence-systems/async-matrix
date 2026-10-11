# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # What a user's presence is.
      class PresenceStatus < Representation
        include Versioned

        # @returns [String] `online`, `offline` or `unavailable`.
        def presence
          self.value[:presence]
        end

        # @returns [String | nil] what the user said about it, where they said anything.
        def status_msg
          self.value[:status_msg]
        end

        # @returns [Integer | nil] how long ago they were active, in milliseconds.
        def last_active_ago
          self.value[:last_active_ago]
        end

        # @returns [Boolean | nil] whether the homeserver counts them as active now.
        def currently_active?
          self.value[:currently_active]
        end
      end

      # Whether a user is around, and what they say about it.
      class Presence
        include Versioned

        # @parameter user_id [String] the user whose presence it is.
        # @returns [String] the path of that user's presence.
        def self.path_for(user_id)
          "#{V3}/presence/#{::Protocol::URL::Encoding.escape(user_id)}/status"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Presence] the presence.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Whether a user is around.
        #
        # @parameter user_id [String] the user to ask about.
        # @returns [PresenceStatus] their presence.
        def get_presence(user_id)
          api::PresenceStatus.get(@resource.with(path: self.class.path_for(user_id)))
        end

        # Say whether this user is around.
        #
        # @parameter user_id [String] the user whose presence it is.
        # @parameter presence [String] `online`, `offline` or `unavailable`.
        # @parameter status_msg [String | nil] what to say about it.
        # @returns [Representation] the empty response.
        def set_presence(user_id, presence, status_msg: nil)
          payload = {presence: presence, status_msg: status_msg}.compact

          api::Representation.put(@resource.with(path: self.class.path_for(user_id)), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
