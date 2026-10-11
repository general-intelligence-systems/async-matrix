# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/read_markers"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Where a user has read up to, which their other devices follow.
      class ReadMarkers
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ReadMarkers] the markers.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Set the read marker, and the receipts which go with it.
        #
        # The marker is for the user's own devices; a receipt is for the room.
        #
        # @parameter room_id [String] the room read in.
        # @parameter fully_read [String | nil] the event the marker goes to.
        # @parameter read [String | nil] the event a public receipt goes to.
        # @parameter read_private [String | nil] the event a private receipt goes to.
        # @returns [Representation] the empty response.
        def set_read_marker(room_id, fully_read: nil, read: nil, read_private: nil)
          payload = {"m.fully_read": fully_read, "m.read": read, "m.read.private": read_private}.compact

          api::Representation.post(@resource.with(path: "#{api::Room.path_for(room_id)}/read_markers"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
