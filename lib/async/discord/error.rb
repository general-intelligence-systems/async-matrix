# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Discord
    # Base error for all Discord API errors.
    class Error < StandardError
      attr_reader :code, :status

      def initialize(code, message, status: nil)
        @code   = code
        @status = status
        super(message)
      end
    end

    # Raised when authentication fails (401).
    class AuthError < Error; end

    # Raised on non-retryable Discord API errors (4xx).
    class ApiError < Error; end

    # Raised when rate-limited and retries are exhausted.
    class RateLimitError < Error; end

    # Raised on server errors after retries exhausted (5xx).
    class ServerError < Error; end

    # Raised when a response body exceeds the configured size limit.
    class ResponseTooLargeError < Error; end

    # Raised when the WebSocket gateway connection fails.
    class GatewayError < Error; end
  end
end

__END__
  describe "Async::Discord::Error" do
    it "stores code and message" do
      err = Async::Discord::Error.new("DISCORD_ERROR", "something broke")
      err.code.should == "DISCORD_ERROR"
      err.message.should == "something broke"
    end

    it "stores optional status" do
      err = Async::Discord::Error.new("ERR", "fail", status: 400)
      err.status.should == 400
    end

    it "defaults status to nil" do
      err = Async::Discord::Error.new("ERR", "fail")
      err.status.should.be.nil
    end

    it "is a StandardError" do
      Async::Discord::Error.new("ERR", "fail").should.be.kind_of StandardError
    end
  end

  it "AuthError inherits from Error" do
    Async::Discord::AuthError.new("AUTH", "bad token").should.be.kind_of Async::Discord::Error
  end

  it "ApiError inherits from Error" do
    Async::Discord::ApiError.new("API", "bad request").should.be.kind_of Async::Discord::Error
  end

  it "RateLimitError inherits from Error" do
    Async::Discord::RateLimitError.new("RATE", "slow down").should.be.kind_of Async::Discord::Error
  end

  it "ServerError inherits from Error" do
    Async::Discord::ServerError.new("SERVER", "500").should.be.kind_of Async::Discord::Error
  end

  it "ResponseTooLargeError inherits from Error" do
    Async::Discord::ResponseTooLargeError.new("LARGE", "too big").should.be.kind_of Async::Discord::Error
  end

  it "GatewayError inherits from Error" do
    Async::Discord::GatewayError.new("GW", "disconnected").should.be.kind_of Async::Discord::Error
  end
