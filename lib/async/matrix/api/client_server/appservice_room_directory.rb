# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/appservice_room_directory"

module Async
  module Matrix
    module ClientServer
      # Whether a room an application service bridges is published.
      class AppserviceRoomDirectory
        include Versioned

        # @parameter network_id [String] the network the application service bridges.
        # @parameter room_id [String] the room on it.
        # @returns [String] the path of whether that room is published.
        def self.path_for(network_id, room_id)
          parts = [network_id, room_id].map{|part| ::Protocol::URL::Encoding.escape(part)}

          "#{V3}/directory/list/appservice/#{parts.join("/")}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AppserviceRoomDirectory] the entries.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Publish a bridged room, or take it out of the directory.
        #
        # Only its application service may say.
        #
        # @parameter network_id [String] the network the application service bridges.
        # @parameter room_id [String] the room to publish or unpublish.
        # @parameter visibility [String] `public` or `private`.
        # @returns [Representation] the empty response.
        def update_appservice_room_directory_visibility(network_id, room_id, visibility)
          api::Representation.put(@resource.with(path: self.class.path_for(network_id, room_id)), {visibility: visibility})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
