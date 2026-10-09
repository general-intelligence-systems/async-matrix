# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Protocol
  module Matrix
    # THE base error for this gem, in both namespaces: Async::Matrix::Error is a
    # constant pointing here, so `rescue Async::Matrix::Error` catches a format
    # failure and a transport failure alike, and every subclass declared as
    # `class AuthError < Error` inside Async::Matrix resolves to this class.
    #
    # It lives under Protocol:: because an error about bytes should not require
    # there to have been a connection -- but the two namespaces ship in one gem,
    # so there is no dependency direction to defend and no reason for consumers
    # to need two rescues.
    class Error < StandardError
      # The Matrix errcode this maps to, when it maps to one. M_BAD_JSON and
      # friends are spec vocabulary, so a format error is entitled to carry one;
      # most carry none.
      attr_reader :errcode

      # The HTTP status, for the failures that came from one.
      attr_reader :status

      # TWO CALLING CONVENTIONS, deliberately, because this class serves both
      # layers:
      #
      #   Error.new("M_UNKNOWN_TOKEN", "token expired", status: 401)
      #   raise MalformedError, "megolm ciphertext must be a string"
      #
      # The first is how the transport has always raised, and changing it would
      # break every caller. The second is what `raise Klass, "message"` does,
      # which is how a format error reads naturally. A lone argument is the
      # message; two are errcode then message.
      def initialize(errcode = nil, message = nil, status: nil)
        @status = status

        if message.nil?
          @errcode = nil
          super(errcode)
        else
          @errcode = errcode
          super(message)
        end
      end
    end
  end
end
