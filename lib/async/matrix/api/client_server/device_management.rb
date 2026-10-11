# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/device_management"

module Async
  module Matrix
    module ClientServer
      # One device this user has logged in from.
      class Device < Representation
        include Versioned

        # @returns [String] the ID of the device.
        def device_id
          self.value[:device_id]
        end

        # @returns [String | nil] the name the user gave it.
        def display_name
          self.value[:display_name]
        end

        # @returns [String | nil] the IP it was last seen from.
        def last_seen_ip
          self.value[:last_seen_ip]
        end

        # @returns [Integer | nil] when it was last seen, in milliseconds since the epoch.
        def last_seen_ts
          self.value[:last_seen_ts]
        end
      end

      # Every device this user has logged in from.
      class Devices < Representation
        include Versioned
        include Enumerable

        # @returns [Array(Hash)] the devices, as the server described them.
        def devices
          self.value[:devices] || []
        end

        # Enumerate over each device.
        #
        # @yields {|device| ...}
        #   @parameter device [Hash] the device.
        def each(&block)
          if block_given?
            self.devices.each(&block)
          else
            to_enum
          end
        end

        # @returns [Array(String)] the ID of each device.
        def ids
          self.devices.map{|device| device[:device_id]}
        end

        # @parameter device_id [String] the device to look for.
        # @returns [Boolean] whether the user has it.
        def include?(device_id)
          self.ids.include?(device_id)
        end
      end

      # The devices a user has logged in from, which an encrypted client tracks.
      class DeviceManagement
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [DeviceManagement] the devices.
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

        # @returns [Devices] every device this user has.
        def get_devices
          api::Devices.get(@resource.with(path: "#{V3}/devices"))
        end

        # @parameter device_id [String] the device to look up.
        # @returns [Device] the device.
        def get_device(device_id)
          api::Device.get(@resource.with(path: self.path_for(device_id)))
        end

        # Rename a device.
        #
        # @parameter device_id [String] the device to rename.
        # @parameter display_name [String] the name to give it.
        # @returns [Representation] the empty response.
        def update_device(device_id, display_name:)
          payload = {display_name: display_name}

          api::Representation.put(@resource.with(path: self.path_for(device_id)), payload)
        end

        # Log a device out, which requires authenticating again.
        #
        # @parameter device_id [String] the device to remove.
        # @parameter auth [Hash | nil] the user interactive authentication to answer with.
        # @returns [Representation] the empty response.
        def delete_device(device_id, auth: nil)
          payload = {auth: auth}.compact

          api::Representation.delete(@resource.with(path: self.path_for(device_id)), payload)
        end

        # Log several devices out at once.
        #
        # @parameter device_ids [Array(String)] the devices to remove.
        # @parameter auth [Hash | nil] the user interactive authentication to answer with.
        # @returns [Representation] the empty response.
        def delete_devices(device_ids, auth: nil)
          payload = {devices: device_ids, auth: auth}.compact

          api::Representation.post(@resource.with(path: "#{V3}/delete_devices"), payload)
        end

        private

        # @parameter device_id [String] the device.
        # @returns [String] the path of one device.
        def path_for(device_id)
          "#{V3}/devices/#{::Protocol::URL::Encoding.escape(device_id)}"
        end
      end
    end
  end
end
