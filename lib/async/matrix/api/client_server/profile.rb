# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # A user's display name, avatar and other fields.
      #
      # The operations are not written yet: this is the class `profile-v1.19.yaml` names.
      class Profile
        include Versioned

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

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
