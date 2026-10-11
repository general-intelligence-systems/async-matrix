# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ApplicationService
      # Whether an application service is answering.
      class Ping
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Ping] the ping.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Answer a ping, which is how a homeserver checks the token it was given.
        #
        # @parameter transaction_id [String | nil] the transaction to quote back.
        # @returns [Representation] the empty response.
        def ping(transaction_id: nil)
          payload = {transaction_id: transaction_id}.compact

          api::Representation.post(@resource.with(path: "#{APP_V1}/ping"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
