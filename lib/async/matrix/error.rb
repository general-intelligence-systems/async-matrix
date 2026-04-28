# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"

module Async
  module Matrix
    class Error < StandardError
      attr_reader :errcode, :status

      def initialize(errcode, message, status: nil)
        @errcode = errcode
        @status = status
        super(message)
      end
    end

    class NotFoundError < Error; end
    class BadJsonError < Error; end
    class AuthError < Error; end
    class HomeserverError < Error; end
    class InvalidEndpointError < Error; end
    class ResponseTooLargeError < Error; end
  end
end

test do
  describe "Async::Matrix::Error" do
    it "stores errcode and message" do
      err = Async::Matrix::Error.new("M_UNKNOWN", "something broke")
      err.errcode.should == "M_UNKNOWN"
      err.message.should == "something broke"
    end

    it "stores optional status" do
      err = Async::Matrix::Error.new("M_UNKNOWN", "bad", status: 400)
      err.status.should == 400
    end

    it "defaults status to nil" do
      Async::Matrix::Error.new("M_UNKNOWN", "bad").status.should.be.nil
    end

    it "is a StandardError" do
      Async::Matrix::Error.new("M_UNKNOWN", "bad").should.be.kind_of StandardError
    end
  end

  it "NotFoundError inherits from Error" do
    Async::Matrix::NotFoundError.new("M_NOT_FOUND", "gone").should.be.kind_of Async::Matrix::Error
  end

  it "BadJsonError inherits from Error" do
    Async::Matrix::BadJsonError.new("M_BAD_JSON", "invalid").should.be.kind_of Async::Matrix::Error
  end

  it "AuthError inherits from Error" do
    Async::Matrix::AuthError.new("M_FORBIDDEN", "denied").should.be.kind_of Async::Matrix::Error
  end

  it "HomeserverError inherits from Error" do
    Async::Matrix::HomeserverError.new("M_UNKNOWN", "upstream").should.be.kind_of Async::Matrix::Error
  end

  it "ResponseTooLargeError inherits from Error" do
    Async::Matrix::ResponseTooLargeError.new("M_TOO_LARGE", "too big").should.be.kind_of Async::Matrix::Error
  end
end
