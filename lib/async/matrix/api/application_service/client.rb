# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/resource"

require_relative "../../paths"
require_relative "../../version"
require_relative "../../versioned"
require_relative "../../versions"
require_relative "../../abstract/api/application_service/client"
require_relative "ping"
require_relative "protocols"
require_relative "query_room"
require_relative "query_user"
require_relative "transactions"

module Async
  module Matrix
    # The application service API, which a bridge serves.
    module ApplicationService
      # A client for the Matrix application service API.
      #
      # These operations are served by a bridge, and called by the homeserver which registered it.
      class Client < Async::REST::Resource
        include Versioned

        class << self
          # The client for a given specification version.
          #
          # @parameter version [String | Symbol] e.g. `"v1.19"` or `"1.19"`.
          # @returns [Class(Client)] the client for that version.
          def [](version)
            Versions[version, self.namespace]::Client
          end
        end

        # The user agent supplied with every request.
        USER_AGENT = "async-matrix/#{VERSION}"

        # Every client carries the user agent, with or without a token.
        #
        # @parameter delegate [Async::HTTP::Middleware] what handles requests.
        # @parameter reference [Protocol::URL::Reference] the base path and parameters.
        # @parameter headers [Protocol::HTTP::Headers] the headers every request carries.
        def initialize(delegate, reference = ::Protocol::URL::Reference.parse, headers = ::Protocol::HTTP::Headers.new)
          super(delegate, reference, headers)

          unless @headers["user-agent"]
            @headers = @headers.merge("user-agent" => USER_AGENT)
          end
        end

        # Derive a client which carries the registration's token.
        #
        # @parameter hs_token [String] the token from the registration.
        # @returns [Client] a client which carries it.
        def authenticated(hs_token)
          self.with(headers: {"authorization" => "Bearer #{hs_token}"})
        end

        # @returns [Transactions] the events to hand over.
        def transactions
          api::Transactions.for(self)
        end

        # @returns [QueryUser] whether a user is the service's own.
        def query_user
          api::QueryUser.for(self)
        end

        # @returns [QueryRoom] whether a room alias is the service's own.
        def query_room
          api::QueryRoom.for(self)
        end

        # @returns [Protocols] the networks the service bridges to.
        def protocols
          api::Protocols.for(self)
        end
      end
    end
  end
end
