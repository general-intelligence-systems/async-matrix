# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "console"

require_relative "device"

module Async
  module Matrix
    module E2EE
      # Which devices each user has, kept current from sync.
      #
      # A batch says whose device list changed, not what it changed to, so a user is queried when next wanted.
      class Devices
        # @parameter client [Async::Matrix::ClientServer::Client] an authenticated client.
        def initialize(client)
          @client = client

          @devices = {}
          @stale = {}
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
          end
        end

        # Note everything a sync batch said about device lists.
        #
        # @parameter sync [Async::Matrix::ClientServer::Sync] the batch.
        def receive(sync)
          self.invalidate(changed: sync.changed_devices, left: sync.left_devices)
        end

        # @parameter user_id [String] the user to ask about.
        # @returns [Boolean] whether their devices must be queried again.
        def stale?(user_id)
          @stale.key?(user_id.to_s) or !@devices.key?(user_id.to_s)
        end

        # The devices of the given users, querying the ones which are stale.
        #
        # @parameter user_ids [Array(String)] the users to ask about.
        # @returns [Hash] the devices, by user ID and then device ID.
        def for(user_ids)
          wanted = user_ids.map(&:to_s)
          missing = wanted.select{|user_id| self.stale?(user_id)}

          unless missing.empty?
            self.query(missing)
          end

          wanted.each_with_object({}) do |user_id, found|
            found[user_id] = @devices[user_id] || {}
          end
        end

        # @parameter user_id [String] the user to ask about.
        # @returns [Array(Device)] their devices.
        def of(user_id)
          self.for([user_id]).fetch(user_id.to_s, {}).values
        end

        # Ask the homeserver for these users' devices, whether or not they are stale.
        #
        # @parameter user_ids [Array(String)] the users to query.
        # @returns [Hash] the devices, by user ID and then device ID.
        def query(user_ids)
          queried = @client.keys.query(user_ids.each_with_object({}){|user_id, asked| asked[user_id] = []})

          Console.debug(self, "Queried device lists.", user_ids: user_ids, failures: queried.failures.keys)

          user_ids.each do |user_id|
            @devices[user_id.to_s] = queried.devices_of(user_id).each_with_object({}) do |(device_id, value), devices|
              devices[device_id.to_s] = Device.new(user_id.to_s, device_id.to_s, value)
            end

            @stale.delete(user_id.to_s)

            Console.debug(self, "Read the devices of a user.", user_id: user_id, device_ids: @devices[user_id.to_s].keys)
          end

          @devices
        end

        # Every device of every user which is known, except this device.
        #
        # @parameter user_ids [Array(String)] the users to include.
        # @parameter except [String | nil] a device of our own to leave out.
        # @returns [Array(Device)] the devices.
        def recipients(user_ids, except: nil)
          self.for(user_ids).each_value.flat_map(&:values).reject do |device|
            device.device_id == except or device.blocked?
          end
        end
      end
    end
  end
end
