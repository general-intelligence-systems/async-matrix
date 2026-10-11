# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/application_service/transactions"

module Async
  module Matrix
    module ApplicationService
      # The events a homeserver hands to an application service.
      class Transactions
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Transactions] the transactions.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Hand the application service a batch of events.
        #
        # The transaction ID makes it idempotent: one seen already is taken again.
        #
        # @parameter txn_id [String] the transaction, which the homeserver numbers.
        # @parameter events [Array(Hash)] the events in it.
        # @parameter payload [Hash] the rest the specification allows, e.g. the ephemeral events.
        # @returns [Representation] the empty response.
        def send_transaction(txn_id, events, **payload)
          path = "#{APP_V1}/transactions/#{::Protocol::URL::Encoding.escape(txn_id)}"

          api::Representation.put(@resource.with(path: path), {events: events, **payload})
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
