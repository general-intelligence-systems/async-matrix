# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # The pushers set on an account.
      class Pushers < Representation
        include Versioned

        # @returns [Array(Hash)] the pushers, each carrying its key and its application.
        def pushers
          self.value[:pushers] || []
        end

        # @returns [Array(String)] the keys the pushers are set against.
        def pushkeys
          self.pushers.map{|pusher| pusher[:pushkey]}
        end

        # @returns [Boolean] whether the account has none.
        def empty?
          self.pushers.empty?
        end
      end

      # The pushers which tell a user's devices about events.
      class Pusher
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Pusher] the pushers.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The pushers set on this account.
        #
        # @returns [Pushers] the pushers.
        def get_pushers
          api::Pushers.get(@resource.with(path: "#{V3}/pushers"))
        end

        # Set a pusher, or take one away by giving its kind as nil.
        #
        # @parameter pushkey [String] the key the application gave for this device.
        # @parameter kind [String | nil] `http`, `email`, or nil to remove the pusher.
        # @parameter app_id [String] the application the key belongs to.
        # @parameter payload [Hash] the rest the specification allows, e.g. `data:`, `lang:`.
        # @returns [Representation] the empty response.
        def post_pusher(pushkey, kind, app_id, **payload)
          body = {pushkey: pushkey, kind: kind, app_id: app_id, **payload}

          api::Representation.post(@resource.with(path: "#{V3}/pushers/set"), body)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
