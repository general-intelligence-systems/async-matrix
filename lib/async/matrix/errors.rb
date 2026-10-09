# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../../protocol/matrix/errors"

module Async
  module Matrix
    # One error base for the whole gem. See Protocol::Matrix::Errors::Error.
    #
    # A CONSTANT, NOT A SUBCLASS: the subclasses below are declared against
    # Protocol::Matrix::Errors::Error directly, so `rescue Async::Matrix::Error`
    # catches everything -- transport failures and format failures together.
    Error = ::Protocol::Matrix::Errors::Error

    class AuthError < Error; end

    class BadJsonError < Error; end

    class HomeserverError < Error; end

    class InvalidEndpointError < Error; end

    class NotFoundError < Error; end

    class ResponseTooLargeError < Error; end

    # A Matrix standard error response body: `{"errcode": ..., "error": ...}`.
    # Both {Client} and {Client::Media} parse failed responses into one of these.
    class ErrorResponse
      attr_reader :errcode, :error

      def initialize(data)
        @errcode = data["errcode"]
        @error   = data["error"]
      end
    end
  end
end

__END__
  describe "Async::Matrix::Error" do
    it "is Protocol::Matrix::Errors::Error" do
      Async::Matrix::Error.should.equal Protocol::Matrix::Errors::Error
    end

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

  describe "Async::Matrix transport errors" do
    it "AuthError inherits from Error" do
      Async::Matrix::AuthError.new("M_FORBIDDEN", "denied").should.be.kind_of Async::Matrix::Error
    end

    it "BadJsonError inherits from Error" do
      Async::Matrix::BadJsonError.new("M_BAD_JSON", "invalid").should.be.kind_of Async::Matrix::Error
    end

    it "HomeserverError inherits from Error" do
      Async::Matrix::HomeserverError.new("M_UNKNOWN", "upstream").should.be.kind_of Async::Matrix::Error
    end

    it "InvalidEndpointError inherits from Error" do
      Async::Matrix::InvalidEndpointError.new("M_UNRECOGNIZED", "no such route").should.be.kind_of Async::Matrix::Error
    end

    it "NotFoundError inherits from Error" do
      Async::Matrix::NotFoundError.new("M_NOT_FOUND", "gone").should.be.kind_of Async::Matrix::Error
    end

    it "ResponseTooLargeError inherits from Error" do
      Async::Matrix::ResponseTooLargeError.new("M_TOO_LARGE", "too big").should.be.kind_of Async::Matrix::Error
    end
  end

  describe "Async::Matrix::ErrorResponse" do
    it "parses errcode and error" do
      resp = Async::Matrix::ErrorResponse.new({
        "errcode" => "M_FORBIDDEN",
        "error" => "Access denied"
      })
      resp.errcode.should == "M_FORBIDDEN"
      resp.error.should == "Access denied"
    end

    it "handles missing fields" do
      resp = Async::Matrix::ErrorResponse.new({})
      resp.errcode.should.be.nil
      resp.error.should.be.nil
    end
  end