# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/representation"

require_relative "../../paths"
require_relative "../../versioned"
require_relative "../../wrapper/lenient"
require_relative "../../abstract/api/push_gateway/push_notifier"

module Async
  module Matrix
    module PushGateway
      # What a push gateway did with a notification.
      #
      # Read leniently: a gateway sends a document without declaring one. See {Wrapper::Lenient}.
      class Notified < Async::REST::Representation[Wrapper::Lenient]
        include Versioned

        # The push keys the gateway will not deliver to again.
        #
        # A rejected key is one the application forgot.
        #
        # @returns [Array(String)] the keys.
        def rejected
          self.value[:rejected] || []
        end

        # @returns [Boolean] whether the gateway accepted every key.
        def accepted?
          self.rejected.empty?
        end
      end

      # Telling a push gateway that something happened.
      class PushNotifier
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PushNotifier] the notifier.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Tell the gateway about an event, so that it can push.
        #
        # No authentication is required.
        #
        # @parameter notification [Hash] the event, its counts, and the devices to push to.
        # @returns [Notified] the keys the gateway rejected.
        def notify(notification)
          api::Notified.post(@resource.with(path: "#{PUSH_V1}/notify"), {notification: notification})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
