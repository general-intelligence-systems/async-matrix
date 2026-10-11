# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/resource"

require_relative "../../paths"
require_relative "../../version"
require_relative "../../versioned"
require_relative "../../versions"
require_relative "push_notifier"

module Async
  module Matrix
    # The push gateway API, which delivers a notification.
    module PushGateway
      # A client for the Matrix push gateway API.
      #
      # A push gateway belongs to whoever wrote the application, so a homeserver is what calls it.
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

        # Every client carries the user agent.
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

        # @returns [PushNotifier] telling the gateway that something happened.
        def push_notifier
          api::PushNotifier.for(self)
        end
      end
    end
  end
end
