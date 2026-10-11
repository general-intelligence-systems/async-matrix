# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/cross_signing"

module Async
  module Matrix
    module ClientServer
      # The response to uploading signatures, which reports the ones it would not take.
      class UploadedSignatures < Representation
        include Versioned

        # @returns [Hash] the signatures which were rejected, by user ID.
        def failures
          self.value[:failures] || {}
        end

        # @returns [Boolean] whether every signature was accepted.
        def accepted?
          self.failures.empty?
        end
      end

      # The keys which let one device vouch for another, and for another user.
      #
      # The keys are opaque here: this uploads what something else signed.
      class CrossSigning
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [CrossSigning] the keys.
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

        # Publish the cross signing keys.
        #
        # @parameter master_key [Hash | nil] the key which signs the other two.
        # @parameter self_signing_key [Hash | nil] the key which signs this user's devices.
        # @parameter user_signing_key [Hash | nil] the key which signs other users.
        # @parameter auth [Hash | nil] the user interactive authentication to answer with.
        # @returns [Representation] the empty response.
        def upload_cross_signing_keys(master_key: nil, self_signing_key: nil, user_signing_key: nil, auth: nil)
          payload = {
            master_key: master_key,
            self_signing_key: self_signing_key,
            user_signing_key: user_signing_key,
            auth: auth,
          }.compact

          api::Representation.post(@resource.with(path: "#{V3}/keys/device_signing/upload"), payload)
        end

        # Publish signatures made with those keys.
        #
        # @parameter signatures [Hash] the signatures, by user ID and then key or device ID.
        # @returns [UploadedSignatures] which signatures were rejected.
        def upload_cross_signing_signatures(signatures)
          api::UploadedSignatures.post(@resource.with(path: "#{V3}/keys/signatures/upload"), signatures)
        end
      end
    end
  end
end
