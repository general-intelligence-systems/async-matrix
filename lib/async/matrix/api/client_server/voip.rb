# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/voip"

module Async
  module Matrix
    module ClientServer
      # The TURN server to use, and the credentials for it.
      class TurnServer < Representation
        include Versioned

        # @returns [String | nil] the username to authenticate with.
        def username
          self.value[:username]
        end

        # @returns [String | nil] the password to authenticate with.
        def password
          self.value[:password]
        end

        # @returns [Array(String)] the URIs of the servers.
        def uris
          self.value[:uris] || []
        end

        # @returns [Integer | nil] how long the credentials last, in seconds.
        def ttl
          self.value[:ttl]
        end
      end

      # The TURN server a call should go through.
      class VOIP
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [VOIP] the servers.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # The TURN server a call should go through.
        #
        # A homeserver with none answers with no credentials.
        #
        # @returns [TurnServer] the server, and the credentials for it.
        def get_turn_server
          api::TurnServer.get(@resource.with(path: "#{V3}/voip/turnServer"))
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
