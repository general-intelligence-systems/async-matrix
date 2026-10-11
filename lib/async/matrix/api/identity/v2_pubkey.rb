# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # One of an identity server's keys.
      class PublicKey < Representation
        include Versioned

        # @returns [String] the key, unpadded base64.
        def public_key
          self.value[:public_key]
        end
      end

      # Whether a key is still in use.
      class KeyValidity < Representation
        include Versioned

        # @returns [Boolean] whether it is.
        def valid?
          self.value[:valid]
        end
      end

      # The keys an identity server signs with.
      class V2Pubkey
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2Pubkey] the keys.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # One of the server's long lived keys. No authentication is required.
        #
        # @parameter key_id [String] the key, e.g. `ed25519:0`.
        # @returns [PublicKey] the key itself.
        def get_pub_key_v2(key_id)
          api::PublicKey.get(@resource.with(path: "#{IDENTITY_V2}/pubkey/#{::Protocol::URL::Encoding.escape(key_id)}"))
        end

        # Whether a long lived key is still in use. No authentication is required.
        #
        # @parameter public_key [String] the key to ask about, unpadded base64.
        # @returns [KeyValidity] whether it is.
        def is_pub_key_valid_v2(public_key)
          api::KeyValidity.get(@resource.with(path: "#{IDENTITY_V2}/pubkey/isvalid", parameters: {public_key: public_key}))
        end

        # Whether an ephemeral key is still in use. No authentication is required.
        #
        # @parameter public_key [String] the key to ask about, unpadded base64.
        # @returns [KeyValidity] whether it is.
        def is_ephemeral_pub_key_valid_v2(public_key)
          api::KeyValidity.get(@resource.with(path: "#{IDENTITY_V2}/pubkey/ephemeral/isvalid", parameters: {public_key: public_key}))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
