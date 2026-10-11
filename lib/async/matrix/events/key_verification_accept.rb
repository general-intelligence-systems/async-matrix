# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_accept"

module Async
  module Matrix
    module Events
      class KeyVerificationAccept < Content
        class << self
          def event_type = "m.key.verification.accept"

          def framing = :event
        end

        include Relates

        def transaction_id = @value[:transaction_id]

        def key_agreement_protocol = @value[:key_agreement_protocol]

        def hash_method = @value[:hash]

        def message_authentication_code = @value[:message_authentication_code]

        def short_authentication_string = @value[:short_authentication_string]

        def commitment = @value[:commitment]
      end
    end
  end
end
