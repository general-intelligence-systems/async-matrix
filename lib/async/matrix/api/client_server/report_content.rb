# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"
require_relative "../../abstract/api/client_server/report_content"

module Async
  module Matrix
    module ClientServer
      # Reporting an event, a room or a user to the homeserver's administrators.
      class ReportContent
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [ReportContent] the reports.
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
      end
    end
  end
end
