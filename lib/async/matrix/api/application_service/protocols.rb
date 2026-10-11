# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module ApplicationService
      # What one protocol can be asked for.
      class Protocol < Representation
        include Versioned

        # @returns [Array(Hash)] the fields which name a user on this network.
        def user_fields
          self.value[:user_fields] || []
        end

        # @returns [Array(Hash)] the fields which name a room on this network.
        def location_fields
          self.value[:location_fields] || []
        end

        # @returns [Hash] what each field means.
        def field_types
          self.value[:field_types] || {}
        end

        # @returns [Array(Hash)] the instances of this network the service bridges.
        def instances
          self.value[:instances] || []
        end
      end

      # The rooms or the users a query found.
      class BridgedEntries < Representation
        include Versioned

        # @returns [Array(Hash)] the entries, which the specification sends as a list.
        def entries
          self.value
        end

        # @returns [Boolean] whether it found nothing.
        def empty?
          self.entries.empty?
        end
      end

      # The networks an application service bridges to.
      class Protocols
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Protocols] the protocols.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # @returns [String] the path of what the service bridges to.
        def self.path
          "#{APP_V1}/thirdparty"
        end

        # What one protocol can be asked for.
        #
        # @parameter protocol [String] the protocol to describe.
        # @returns [Protocol] what it can be asked for.
        def get_protocol_metadata(protocol)
          path = "#{self.class.path}/protocol/#{::Protocol::URL::Encoding.escape(protocol)}"

          api::Protocol.get(@resource.with(path: path))
        end

        # The room an alias on a bridged network names.
        #
        # @parameter alias_name [String] the Matrix alias to resolve.
        # @returns [BridgedEntries] the rooms it found.
        def query_location_by_alias(alias_name)
          api::BridgedEntries.get(@resource.with(path: "#{self.class.path}/location", parameters: {alias: alias_name}))
        end

        # The rooms a bridged network has, by its own fields.
        #
        # @parameter protocol [String] the protocol to ask.
        # @parameter fields [Hash] the fields which name the room there.
        # @returns [BridgedEntries] the rooms it found.
        def query_location_by_protocol(protocol, **fields)
          path = "#{self.class.path}/location/#{::Protocol::URL::Encoding.escape(protocol)}"

          api::BridgedEntries.get(@resource.with(path: path, parameters: fields))
        end

        # The user a Matrix ID names on a bridged network.
        #
        # @parameter userid [String] the Matrix user to resolve.
        # @returns [BridgedEntries] the users it found.
        def query_user_by_id(userid)
          api::BridgedEntries.get(@resource.with(path: "#{self.class.path}/user", parameters: {userid: userid}))
        end

        # The users a bridged network has, by its own fields.
        #
        # @parameter protocol [String] the protocol to ask.
        # @parameter fields [Hash] the fields which name the user there.
        # @returns [BridgedEntries] the users it found.
        def query_user_by_protocol(protocol, **fields)
          path = "#{self.class.path}/user/#{::Protocol::URL::Encoding.escape(protocol)}"

          api::BridgedEntries.get(@resource.with(path: path, parameters: fields))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
