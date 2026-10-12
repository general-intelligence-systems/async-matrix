# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/representation"

require_relative "redacted"
require_relative "wrapper/json"

module Async
  module Matrix
    # The base representation for all Matrix responses.
    class Representation < Async::REST::Representation[Wrapper::JSON]
      include Redacted

      # What a pattern reads, which is the document the homeserver answered with.
      #
      # @parameter keys [Array(Symbol) | nil] the names a pattern asked for.
      # @returns [Hash] the value.
      def deconstruct_keys(keys)
        # So a response is matched where it arrives, rather than having to be taken apart first. `[]` cannot do this, because `async-rest` already uses it to derive a sub-resource.
        case self.value
        in Hash => value
          value
        else
          {}
        end
      end
    end
  end
end
