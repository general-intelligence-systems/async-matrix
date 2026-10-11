# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    module E2EE
      # One device of one user, as its owner published it.
      class Device
        # How much this device is trusted, which only its owner's user can decide.
        TRUST = [:unverified, :verified, :blocked].freeze

        # @parameter user_id [String] the user the device belongs to.
        # @parameter device_id [String] the ID of the device.
        # @parameter value [Hash] the device keys the server answered with.
        # @parameter trust [Symbol] how much it is trusted.
        def initialize(user_id, device_id, value, trust: :unverified)
          @user_id = user_id
          @device_id = device_id
          @value = value
          @trust = trust
        end

        # @attribute [String] the user the device belongs to.
        attr :user_id

        # @attribute [String] the ID of the device.
        attr :device_id

        # @attribute [Hash] the device keys the server answered with.
        attr :value

        # @attribute [Symbol] how much the device is trusted.
        attr_accessor :trust

        # @returns [String | nil] the key sessions are established with.
        def curve25519
          self.keys[:"curve25519:#{@device_id}"]
        end

        # @returns [String | nil] the key signatures are made with.
        def ed25519
          self.keys[:"ed25519:#{@device_id}"]
        end

        # @returns [Hash] the public keys, by algorithm and device.
        def keys
          @value[:keys] || {}
        end

        # @returns [Array(String)] the algorithms the device can encrypt with.
        def algorithms
          @value[:algorithms] || []
        end

        # @returns [Hash] the signatures over the device keys.
        def signatures
          @value[:signatures] || {}
        end

        # @returns [String | nil] the name its owner gave it.
        def display_name
          @value.dig(:unsigned, :device_display_name)
        end

        # @returns [Boolean] whether its owner has vouched for it.
        def verified?
          @trust == :verified
        end

        # @returns [Boolean] whether its owner has refused it.
        def blocked?
          @trust == :blocked
        end

        # @parameter algorithm [String] the algorithm to look for.
        # @returns [Boolean] whether the device supports it.
        def supports?(algorithm)
          self.algorithms.include?(algorithm)
        end

        def ==(other)
          other.is_a?(Device) and other.user_id == @user_id and other.device_id == @device_id
        end

        def inspect
          "\#<#{self.class} #{@user_id} #{@device_id} #{@trust}>"
        end
      end
    end
  end
end
