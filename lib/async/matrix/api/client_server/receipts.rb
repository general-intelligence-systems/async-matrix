# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../representation"
require_relative "../../versioned"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Saying how far a user has read.
      class Receipts
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Receipts] the receipts.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Send a receipt, which says how far this user has read.
        #
        # @parameter room_id [String] the room read in.
        # @parameter receipt_type [String] `m.read`, `m.read.private` or `m.fully_read`.
        # @parameter event_id [String] the event read up to.
        # @parameter thread_id [String | nil] the thread read in, where it was a thread.
        # @returns [Representation] the empty response.
        def post_receipt(room_id, receipt_type, event_id, thread_id: nil)
          payload = {thread_id: thread_id}.compact
          path = "#{api::Room.path_for(room_id)}/receipt/#{::Protocol::URL::Encoding.escape(receipt_type)}/#{::Protocol::URL::Encoding.escape(event_id)}"

          api::Representation.post(@resource.with(path: path), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
