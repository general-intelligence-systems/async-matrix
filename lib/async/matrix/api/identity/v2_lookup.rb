# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # What a lookup must hash its addresses with.
      class HashDetails < Representation
        include Versioned

        # @returns [String] the pepper to hash with, which changes.
        def lookup_pepper
          self.value[:lookup_pepper]
        end

        # @returns [Array(String)] the algorithms the server accepts, e.g. `sha256`.
        def algorithms
          self.value[:algorithms] || []
        end
      end

      # The users a lookup found.
      class Mappings < Representation
        include Versioned

        # @returns [Hash] the user behind each address which was known.
        def mappings
          self.value[:mappings] || {}
        end

        # @returns [Boolean] whether none of the addresses were known.
        def empty?
          self.mappings.empty?
        end
      end

      # Looking up the users behind addresses.
      class V2Lookup
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Lookup] the lookup.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The pepper and algorithms a lookup must use.
        #
        # The pepper changes, so it is read before each lookup.
        #
        # @returns [HashDetails] what to hash the addresses with.
        def get_hash_details
          api::HashDetails.get(@resource.with(path: "#{IDENTITY_V2}/hash_details"))
        end

        # The users behind a set of addresses.
        #
        # @parameter algorithm [String] the algorithm to hash with, e.g. `sha256`.
        # @parameter pepper [String] the pepper from {#get_hash_details}.
        # @parameter addresses [Array(String)] the addresses, hashed as the algorithm says.
        # @returns [Mappings] the users which were found.
        def lookup_users_v2(algorithm, pepper, addresses)
          payload = {algorithm: algorithm, pepper: pepper, addresses: addresses}

          api::Mappings.post(@resource.with(path: "#{IDENTITY_V2}/lookup"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
