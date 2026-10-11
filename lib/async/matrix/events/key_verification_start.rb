# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "content"
require_relative "fields"
require_relative "../abstract/events/key_verification_start"

module Async
  module Matrix
    module Events
      class KeyVerificationStart < Content
        class << self
          def event_type = "m.key.verification.start"

          def framing = :event
        end

        include Relates

        def from_device = @value[:from_device]

        def transaction_id = @value[:transaction_id]

        def verification_method = @value[:method]

        def next_method = @value[:next_method]
      end

      class KeyVerificationStartReciprocateV1 < KeyVerificationStart
        class << self
          def event_type = "m.key.verification.start"

          def variant = {method: "m.reciprocate.v1"}
        end

        include Relates

        def from_device = @value[:from_device]

        def transaction_id = @value[:transaction_id]

        def verification_method = @value[:method]

        def secret = @value[:secret]
      end

      class KeyVerificationStartSasV1 < KeyVerificationStart
        class << self
          def event_type = "m.key.verification.start"

          def variant = {method: "m.sas.v1"}
        end

        include Relates

        def from_device = @value[:from_device]

        def transaction_id = @value[:transaction_id]

        def verification_method = @value[:method]

        def key_agreement_protocols = @value[:key_agreement_protocols]

        def hashes = @value[:hashes]

        def message_authentication_codes = @value[:message_authentication_codes]

        def short_authentication_string = @value[:short_authentication_string]
      end
    end
  end
end
