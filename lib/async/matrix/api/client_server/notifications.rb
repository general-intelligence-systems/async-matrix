# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/notifications"

module Async
  module Matrix
    module ClientServer
      # A page of the notifications waiting for a user.
      class Notified < Representation
        include Versioned

        # @returns [Array(Hash)] the notifications in this page, each carrying its event.
        def notifications
          self.value[:notifications] || []
        end

        # @returns [String | nil] the token to ask for the following page from.
        def next_token
          self.value[:next_token]
        end

        # @returns [Boolean] whether this page is empty.
        def empty?
          self.notifications.empty?
        end
      end

      # The notifications a user has waiting.
      class Notifications
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [Notifications] the notifications.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The notifications waiting for this user.
        #
        # @parameter from [String | nil] the token a previous page ended at.
        # @parameter limit [Integer | nil] the most notifications wanted.
        # @parameter only [String | nil] `highlight` to leave out the rest.
        # @returns [Notified] the page of notifications.
        def get_notifications(from: nil, limit: nil, only: nil)
          parameters = {from: from, limit: limit, only: only}.compact

          api::Notified.get(@resource.with(path: "#{V3}/notifications", parameters: parameters))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
