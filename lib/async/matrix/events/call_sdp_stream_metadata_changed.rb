# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "content"
require_relative "fields"

module Async
  module Matrix
    module Events
      class CallSdpStreamMetadataChanged < Content
        class << self
          def event_type = "m.call.sdp_stream_metadata_changed"

          def framing = :room_event
        end

        def call_id = @value[:call_id]

        def voip_version = @value[:version]

        def party_id = @value[:party_id]
      end
    end
  end
end
