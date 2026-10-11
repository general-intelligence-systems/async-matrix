# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/account_data"

module Async
  module Matrix
    module ClientServer
      # A user's own data, which the homeserver keeps but does not read.
      class AccountData
        include Versioned

        # @parameter user_id [String] the user whose own data it is.
        # @returns [String] the path of that user.
        def self.path_for(user_id)
          "#{V3}/user/#{::Protocol::URL::Encoding.escape(user_id)}"
        end

        # @parameter user_id [String] the user whose own data it is.
        # @parameter type [String] the type of data, e.g. `m.direct`.
        # @parameter room_id [String | nil] the room it belongs to, or nil for the account.
        # @returns [String] the path of that data.
        def self.path_for_type(user_id, type, room_id = nil)
          path = self.path_for(user_id)

          if room_id
            path = "#{path}/rooms/#{::Protocol::URL::Encoding.escape(room_id)}"
          end

          "#{path}/account_data/#{::Protocol::URL::Encoding.escape(type)}"
        end

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [AccountData] the storage.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # One type of this user's own data.
        #
        # @parameter user_id [String] the user to read it for.
        # @parameter type [String] the type to read.
        # @returns [Representation] the content, which is whatever was stored.
        def get_account_data(user_id, type)
          api::Representation.get(@resource.with(path: self.class.path_for_type(user_id, type)))
        end

        # Store one type of this user's own data.
        #
        # @parameter user_id [String] the user to store it for.
        # @parameter type [String] the type to store.
        # @parameter content [Hash] the content to store.
        # @returns [Representation] the empty response.
        def set_account_data(user_id, type, content)
          api::Representation.put(@resource.with(path: self.class.path_for_type(user_id, type)), content)
        end

        # One type of this user's own data for one room.
        #
        # @parameter user_id [String] the user to read it for.
        # @parameter room_id [String] the room it belongs to.
        # @parameter type [String] the type to read.
        # @returns [Representation] the content, which is whatever was stored.
        def get_account_data_per_room(user_id, room_id, type)
          api::Representation.get(@resource.with(path: self.class.path_for_type(user_id, type, room_id)))
        end

        # Store one type of this user's own data for one room.
        #
        # @parameter user_id [String] the user to store it for.
        # @parameter room_id [String] the room it belongs to.
        # @parameter type [String] the type to store.
        # @parameter content [Hash] the content to store.
        # @returns [Representation] the empty response.
        def set_account_data_per_room(user_id, room_id, type, content)
          api::Representation.put(@resource.with(path: self.class.path_for_type(user_id, type, room_id)), content)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
