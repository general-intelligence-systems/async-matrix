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
        def initialize
          @devices = {}
          @stale = {}
          @tracking = {}
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
            self.accept_user(user_id.to_s, queried)
          end

          @devices
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
            devices[device_id.to_s] = Device.new(user_id, device_id.to_s, value)
          end

          @stale.delete(user_id)

          Console.debug(self, "Read the devices of a user.", user_id: user_id, device_ids: @devices[user_id].keys)
        end
      end
    end
  end
end
