# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/admin"

module Async
  module Matrix
    module ClientServer
      # Where a user has been connecting from.
      class WhoIs < Representation
        include Versioned

        # @returns [String] the user this describes.
        def user_id
          self.value[:user_id]
        end

        # The devices they have connected from, by device ID.
        #
        # @returns [Hash] the connections of each, as the homeserver reported them.
        def devices
          self.value[:devices] || {}
        end
      end

      # Whether a user is locked out of their account.
      #
      # The endpoint arrived in v1.18, so the field is read by that layer.
      class UserLock < Representation
        include Versioned
      end

      # Whether a user is suspended.
      #
      # The endpoint arrived in v1.18, so the field is read by that layer.
      class UserSuspension < Representation
        include Versioned
      end

      # What the homeserver will tell an administrator about a user.
      class Admin
        include Versioned

        # @parameter user_id [String] the user asked about.
        # @returns [String] the path of what the homeserver knows about them.
        def self.path_for(user_id)
          "#{V3}/admin/whois/#{::Protocol::URL::Encoding.escape(user_id)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Admin] the administration.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Where a user has been connecting from.
        #
        # A homeserver may answer for the user asking, administrator or not.
        #
        # @parameter user_id [String] the user to ask about.
        # @returns [WhoIs] their connections.
        def get_who_is(user_id)
          api::WhoIs.get(@resource.with(path: self.class.path_for(user_id)))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
