# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/backfill"
require_relative "events"
require_relative "parameters"

module Async
  module Matrix
    module ServerServer
      # The events which were missing between what we have and what we heard about.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class MissingEvents < Representation
        include Versioned
      end

      # The events before the ones we have.
      #
      # Backfill answers in a transaction, which is the representation {Events} reads.
      class Backfill
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Backfill] the history.
        def self.for(parent)
          self.new(parent)
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
      end
    end
  end
end
