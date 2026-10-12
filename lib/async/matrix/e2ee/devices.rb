# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "console"

require_relative "device"

module Async
  module Matrix
    module E2EE
      # Which devices each user has.
      #
      # It makes no request: a batch says whose list changed, a caller queries them, and what the homeserver answered is handed back here.
      class Devices
        # @parameter crypto [Crypto | nil] what to check a cross signing signature with.
        def initialize(crypto: nil)
          @crypto = crypto

          @devices = {}
          @stale = {}
          @tracking = {}
          @identities = {}
        end

        # @attribute [Hash] the devices of each user, by user ID and then device ID.
        attr :devices

        # Note that these users' devices changed, and that those users are gone.
        #
        # @parameter changed [Array(String)] the users to query again.
        # @parameter left [Array(String)] the users to forget.
        def invalidate(changed: [], left: [])
          unless changed.empty? and left.empty?
            Console.debug(self, "Invalidating device lists.", changed: changed, left: left)
          end

          changed.each do |user_id|
            @stale[user_id.to_s] = true
          end

          left.each do |user_id|
            @devices.delete(user_id.to_s)
            @stale.delete(user_id.to_s)
            @tracking.delete(user_id.to_s)
          end
        end

        # Take on what a device list query answered.
        #
        # @parameter queried [Async::Matrix::ClientServer::QueriedKeys] what the homeserver said.
        # @returns [Hash] the devices of each user it named.
        def accept(queried)
          queried.device_keys.each_key do |user_id|
            self.accept_identity(user_id.to_s, queried)
            self.accept_user(user_id.to_s, queried)
          end

          @devices
        end

        # @attribute [Hash] every identity which is known, by user ID.
        attr :identities

        # The cross signing keys a user published, which is their identity.
        #
        # @parameter user_id [String] the user to ask about.
        # @returns [Hash | nil] their master and self signing keys.
        def identity(user_id)
          @identities[user_id.to_s]
        end

        # Stop believing anything about a user, because their identity changed under us.
        #
        # @parameter user_id [String] the user to distrust.
        def untrust(user_id)
          self.of(user_id).each do |device|
            device.trust = :unverified
            device.cross_signed = false
          end

          @stale[user_id.to_s] = true
        end

        # @parameter user_id [String] the user to ask about.
        # @returns [Boolean] whether their devices must be queried again.
        def stale?(user_id)
          @stale.key?(user_id.to_s) or !@devices.key?(user_id.to_s)
        end

        # Follow this user's devices from now on, because we share an encrypted room with them.
        #
        # @parameter user_id [String] the user to follow.
        def track(user_id)
          @tracking[user_id.to_s] = true
          @stale[user_id.to_s] = true
        end

        # @returns [Array(String)] the users whose devices are followed.
        def tracking
          @tracking.keys
        end

        # @returns [Array(String)] the users whose devices should be queried again.
        def querying
          @stale.keys
        end

        # @parameter user_id [String] the user to ask about.
        # @returns [Array(Device)] their devices, as last answered.
        def of(user_id)
          (@devices[user_id.to_s] || {}).values
        end

        # @parameter user_id [String] the user to ask about.
        # @parameter device_id [String] the device.
        # @returns [Device | nil] that device, if it is known.
        def [](user_id, device_id)
          (@devices[user_id.to_s] || {})[device_id.to_s]
        end

        # The device which holds a given identity key, which is how an Olm message names its sender.
        #
        # @parameter user_id [String] the user it claims to be from.
        # @parameter curve25519 [String] the identity key it was encrypted with.
        # @returns [Device | nil] the device, if that user has one with that key.
        def by_curve25519(user_id, curve25519)
          self.of(user_id).find{|device| device.curve25519 == curve25519}
        end

        # @parameter user_id [String] the user to ask about.
        # @parameter device_id [String] the device.
        # @returns [Boolean] whether that device is verified.
        def verified?(user_id, device_id)
          device = self[user_id, device_id]

          !device.nil? && device.verified?
        end

        # @parameter user_id [String] the user to ask about.
        # @returns [Array(Device)] their verified devices.
        def verified_of(user_id)
          self.of(user_id).select(&:verified?)
        end

        # Every device of every user named, except this device.
        #
        # @parameter user_ids [Array(String)] the users to include.
        # @parameter except [String | nil] a device of our own to leave out.
        # @returns [Array(Device)] the devices.
        def recipients(user_ids, except: nil)
          user_ids.flat_map{|user_id| self.of(user_id)}.reject do |device|
            device.device_id == except or device.blocked?
          end
        end

        private

        # Take on one user's devices, which replaces whatever was held for them.
        #
        # @parameter user_id [String] the user.
        # @parameter queried [Async::Matrix::ClientServer::QueriedKeys] what the homeserver said.
        def accept_user(user_id, queried)
          @devices[user_id] = queried.devices_of(user_id).each_with_object({}) do |(device_id, value), devices|
            devices[device_id.to_s] = Device.new(user_id, device_id.to_s, value, cross_signed: self.cross_signed?(user_id, value))
          end

          @stale.delete(user_id)

          Console.debug(self, "Read the devices of a user.", user_id: user_id, device_ids: @devices[user_id].keys)
        end

        # What a user's cross signing keys say, which is what their devices are measured against.
        #
        # @parameter user_id [String] the user.
        # @parameter queried [Async::Matrix::ClientServer::QueriedKeys] what the homeserver said.
        def accept_identity(user_id, queried)
          master = queried.master_keys[user_id.to_sym]
          self_signing = queried.self_signing_keys[user_id.to_sym]

          case {master: master, self_signing: self_signing}
          in {master: {keys: Hash => master_keys}, self_signing: {keys: Hash => signing_keys}}
            @identities[user_id] = {
              user_id: user_id,
              master: master_keys.each_value.first,
              self_signing: signing_keys.each_value.first,
              object: master,
            }
          else
            @identities.delete(user_id)
          end
        end

        # Whether this device carries a signature by its owner's self signing key.
        #
        # The signature is checked where there is something to check it with, because its presence alone says only that somebody wrote one.
        #
        # @parameter user_id [String] the user.
        # @parameter value [Hash] the device keys the homeserver answered with.
        # @returns [Boolean] whether it is cross signed.
        def cross_signed?(user_id, value)
          signing = @identities.dig(user_id, :self_signing)
          signature = value.dig(:signatures, user_id.to_sym, :"ed25519:#{signing}")

          case {signing: signing, signature: signature, crypto: @crypto}
          in {signing: String, signature: String => claimed, crypto: Crypto => crypto}
            crypto.verify(value.reject{|name, _| name == :signatures}, key: signing, signature: claimed)
          in {signing: String, signature: String}
            true
          else
            false
          end
        end
      end
    end
  end
end
