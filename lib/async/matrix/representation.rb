# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/representation"

require_relative "events"
require_relative "wrapper"

module Async
  module Matrix
    # The base representation for all Matrix responses.
    class Representation < Async::REST::Representation[Wrapper]
      # The events built for this representation's version, so that an event is read with the
      # fields its own version describes rather than the newest ones.
      #
      # @returns [Events::Registry] the registry.
      def events
        Events.registry(self.version)
      end
    end
  end
end
