# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/server_server/transactions"

module Async
  module Matrix
    module ServerServer
      # What became of each event in a transaction.
      #
      # The endpoint arrived in v1.1, so the fields are read by that layer.
      class TransactionResult < Representation
        include Versioned
      end

      # The events and ephemeral data pushed from one server to another.
      class Transactions
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Transactions] the push.
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
