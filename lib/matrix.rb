# frozen_string_literal: true

require "console"

# Minimal Matrix module providing the interfaces expected by the echo bot example.
# This will be replaced by the full async-matrix library as it matures.
module Matrix
  def self.logger
    Console
  end

  module Errors
    class Base < StandardError
      attr_reader :errcode, :status

      def initialize(errcode, message, status: nil)
        @errcode = errcode
        @status = status
        super(message)
      end
    end

    class NotFound < Base; end
    class BadJson < Base; end
    class Auth < Base; end
    class Homeserver < Base; end
  end

  module ApplicationService
    module Models
      class Event
        attr_reader :type, :sender, :room_id, :state_key, :content, :event_id

        def initialize(data)
          @type      = data["type"]
          @sender    = data["sender"]
          @room_id   = data["room_id"]
          @state_key = data["state_key"]
          @event_id  = data["event_id"]
          @content   = Content.new(data["content"] || {})
        end
      end

      class Content
        attr_reader :msgtype, :body, :membership

        def initialize(data)
          @msgtype    = data["msgtype"]
          @body       = data["body"]
          @membership = data["membership"]
        end
      end

      class Transaction
        attr_reader :events, :ephemeral

        def initialize(data)
          @events    = (data["events"] || []).map { |e| Event.new(e) }
          @ephemeral = (data["de.sorunome.msc2409.ephemeral"] || data["ephemeral"] || []).map { |e| Event.new(e) }
        end
      end

      class ErrorResponse
        attr_reader :errcode, :error

        def initialize(data)
          @errcode = data["errcode"]
          @error   = data["error"]
        end
      end
    end
  end
end
