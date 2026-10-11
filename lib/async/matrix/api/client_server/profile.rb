# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../removals"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/profile"

module Async
  module Matrix
    module ClientServer
      # A user's whole profile.
      class UserProfile < Representation
        include Versioned

        # @returns [String | nil] the name the user is shown as, where they set one.
        def displayname
          self.value[:displayname]
        end

        # @returns [String | nil] the `mxc://` URI of their avatar, where they set one.
        def avatar_url
          self.value[:avatar_url]
        end
      end

      # One field of a profile.
      #
      # The field endpoints arrived in v1.16, so the value is read by that layer.
      class ProfileField < Representation
        include Versioned
      end

      # A user's display name, avatar and other fields.
      #
      # v1.16 replaced the named fields with one field by key, so each is read by its own layer.
      class Profile
        include Versioned

        # @parameter user_id [String] the user whose profile it is.
        # @returns [String] the path of that user's profile.
        def self.path_for(user_id)
          "#{V3}/profile/#{::Protocol::URL::Encoding.escape(user_id)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Profile] the profile.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # A user's whole profile, which every version answers.
        #
        # @parameter user_id [String] the user to ask about.
        # @returns [UserProfile] their profile.
        def get_user_profile(user_id)
          api::UserProfile.get(@resource.with(path: self.class.path_for(user_id)))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
