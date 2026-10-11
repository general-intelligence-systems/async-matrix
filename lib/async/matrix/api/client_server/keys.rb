# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/keys"

module Async
  module Matrix
    module ClientServer
      # The response to uploading keys, which says how many the server now holds.
      class UploadedKeys < Representation
        include Versioned

        # @returns [Hash] the number of one time keys the server holds, by algorithm.
        def one_time_key_counts
          self.value[:one_time_key_counts] || {}
        end

        # @parameter algorithm [String] the algorithm to count, e.g. `signed_curve25519`.
        # @returns [Integer] how many keys remain.
        def count(algorithm)
          self.one_time_key_counts[algorithm.to_sym] || 0
        end
      end

      # The device and cross signing keys of the users which were asked about.
      class QueriedKeys < Representation
        include Versioned

        # @returns [Hash] the device keys, by user ID and then device ID.
        def device_keys
          self.value[:device_keys] || {}
        end

        # @returns [Hash] the homeservers which could not be reached.
        def failures
          self.value[:failures] || {}
        end

        # @returns [Hash] the master cross signing keys, by user ID.
        def master_keys
          self.value[:master_keys] || {}
        end

        # @returns [Hash] the self signing keys, by user ID.
        def self_signing_keys
          self.value[:self_signing_keys] || {}
        end

        # @returns [Hash] the user signing keys, by user ID.
        def user_signing_keys
          self.value[:user_signing_keys] || {}
        end

        # @parameter user_id [String] the user to look up.
        # @returns [Hash] that user's devices, by device ID.
        def devices_of(user_id)
          self.device_keys[user_id.to_sym] || {}
        end
      end

      # The one time keys which were claimed, one per device.
      class ClaimedKeys < Representation
        include Versioned

        # @returns [Hash] the keys, by user ID and then device ID.
        def one_time_keys
          self.value[:one_time_keys] || {}
        end

        # @returns [Hash] the homeservers which could not be reached.
        def failures
          self.value[:failures] || {}
        end
      end

      # Which users' device lists changed between two sync tokens.
      class KeyChanges < Representation
        include Versioned

        # @returns [Array(String)] the users whose device lists changed.
        def changed
          self.value[:changed] || []
        end

        # @returns [Array(String)] the users who are no longer shared with.
        def left
          self.value[:left] || []
        end
      end

      # The end to end encryption keys of this user and the users they share rooms with.
      #
      # The keys are opaque here: this uploads, queries and claims what something else holds.
      class Keys
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Keys] the keys.
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

        # Publish this device's identity and one time keys.
        #
        # @parameter device_keys [Hash | nil] the identity keys, signed by the device.
        # @parameter one_time_keys [Hash | nil] the one time keys, by algorithm and ID.
        # @returns [UploadedKeys] how many one time keys the server now holds.
        def upload_keys(**options)
          self.upload_payload(self.upload_fields(**options))
        end

        # Ask for the keys of the given devices.
        #
        # @parameter device_keys [Hash] the devices to ask about, by user ID.
        # @parameter timeout [Integer | nil] how long to wait for other homeservers.
        # @parameter token [String | nil] the sync token the query is made as of.
        # @returns [QueriedKeys] the keys.
        def query_keys(device_keys, timeout: nil, token: nil)
          payload = {device_keys: device_keys, timeout: timeout}.compact

          if token
            unless self.query_accepts_token?
              raise ArgumentError, "A query token is not accepted from v1.7!"
            end

            payload[:token] = token
          end

          api::QueriedKeys.post(@resource.with(path: "#{V3}/keys/query"), payload)
        end

        # Claim one time keys, so that a session can be established with those devices.
        #
        # @parameter one_time_keys [Hash] the algorithm wanted, by user ID and device ID.
        # @parameter timeout [Integer | nil] how long to wait for other homeservers.
        # @returns [ClaimedKeys] the keys, which the server will not hand out again.
        def claim_keys(one_time_keys, timeout: nil)
          payload = {one_time_keys: one_time_keys, timeout: timeout}.compact

          api::ClaimedKeys.post(@resource.with(path: "#{V3}/keys/claim"), payload)
        end

        # Which device lists changed between two sync tokens.
        #
        # @parameter from [String] the sync token to start from.
        # @parameter to [String] the sync token to end at.
        # @returns [KeyChanges] the users whose devices changed.
        def get_keys_changes(from:, to:)
          parameters = {from: from, to: to}

          api::KeyChanges.get(@resource.with(path: "#{V3}/keys/changes", parameters: parameters))
        end

        # Whether a query may carry a `token`, as it could before v1.7.
        #
        # @returns [Boolean] whether the parameter is accepted.
        def query_accepts_token?
          false
        end

        # The fields an upload sends, which the layers add to.
        #
        # @parameter device_keys [Hash | nil] the identity keys, signed by the device.
        # @parameter one_time_keys [Hash | nil] the one time keys, by algorithm and ID.
        # @returns [Hash] the fields.
        def upload_fields(device_keys: nil, one_time_keys: nil)
          {device_keys: device_keys, one_time_keys: one_time_keys}.compact
        end

        # Make the upload request.
        #
        # @parameter payload [Hash] the fields to send.
        # @returns [UploadedKeys] how many one time keys the server now holds.
        def upload_payload(payload)
          api::UploadedKeys.post(@resource.with(path: "#{V3}/keys/upload"), payload)
        end

        def close
          @resource.close
        end
      end
    end
  end
end
