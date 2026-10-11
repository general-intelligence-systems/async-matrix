# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/to_device"

module Async
  module Matrix
    module ClientServer
      # Messages sent to a device rather than into a room.
      #
      # This is how encryption keys travel, and they arrive in a sync batch's `to_device`.
      class ToDevice
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ToDevice] the sender.
        def self.for(parent)
          self.new(parent)
        end

        # @returns [String] a transaction ID, which makes sending idempotent.
        def self.transaction_id
          SecureRandom.uuid
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

        # Send an event to the given devices.
        #
        # @parameter type [String] the event type, e.g. `m.room_key`.
        # @parameter messages [Hash] the content, by user ID and then device ID.
        # @parameter transaction_id [String] a unique ID which makes this idempotent.
        # @returns [Representation] the empty response.
        def send_to_device(type, messages, transaction_id: self.class.transaction_id)
          path = "#{V3}/sendToDevice/#{::Protocol::URL::Encoding.escape(type)}/#{::Protocol::URL::Encoding.escape(transaction_id)}"

          api::Representation.put(@resource.with(path: path), {messages: messages})
        end

        def close
          @resource.close
        end
      end
    end
  end
end
