# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../versioned"
require_relative "rooms"

module Async
  module Matrix
    module ClientServer
      # Redacting an event, which strips it of everything but its shape.
      class Redaction
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Redaction] the redactions.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Redact an event, which asks the homeserver to strip its content.
        #
        # @parameter room_id [String] the room the event is in.
        # @parameter event_id [String] the event to redact.
        # @parameter reason [String | nil] what to record as the reason.
        # @parameter transaction_id [String] the ID which makes the request idempotent.
        # @returns [SentEvent] the redaction, which is itself an event.
        def redact_event(room_id, event_id, reason: nil, transaction_id: api::Room.transaction_id)
          payload = {reason: reason}.compact
          path = "#{api::Room.path_for(room_id)}/redact/#{::Protocol::URL::Encoding.escape(event_id)}/#{::Protocol::URL::Encoding.escape(transaction_id)}"

          api::SentEvent.put(@resource.with(path: path), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
