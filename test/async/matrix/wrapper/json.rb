# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "sus/fixtures/async/reactor_context"

require "async/matrix"

# Answers whatever it was built with, recording each request as it arrived.
class RefusingDelegate < Protocol::HTTP::Middleware
  def initialize(status, headers, body)
    super(nil)

    @requests = 0
    @status = status
    @headers = headers
    @body = body
  end

  # @attribute [Integer] how many requests arrived.
  attr :requests

  def call(request)
    @requests += 1

    Protocol::HTTP::Response[@status, @headers, @body]
  end

  def close
  end
end

describe Async::Matrix::Wrapper::JSON do
  include Sus::Fixtures::Async::ReactorContext

  let(:reference) {Protocol::URL::Reference.parse("/_matrix/client/v3/sync")}
  let(:resource) {Async::Matrix::ClientServer::Client.new(delegate, reference)}

  with "a refusal carrying an error code" do
    let(:delegate) do
      RefusingDelegate.new(403, {"content-type" => "application/json"}, ["{\"errcode\":\"M_FORBIDDEN\",\"error\":\"Nope\"}"])
    end

    it "raises with the code and message the body gave" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => raised
        error = raised
      end

      expect(error).not.to be_nil
      expect(error.status).to be == 403
      expect(error.errcode).to be == "M_FORBIDDEN"
      expect(error.message).to be == "M_FORBIDDEN: Nope"
    end
  end

  with "a refusal with no body to read" do
    let(:delegate) {RefusingDelegate.new(502, {}, [])}

    it "raises with the status alone" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => raised
        error = raised
      end

      expect(error).not.to be_nil
      expect(error.status).to be == 502
      expect(error.errcode).to be_nil
    end
  end

  with "a rate limited request" do
    let(:delegate) do
      RefusingDelegate.new(429, {"retry-after" => "0", "content-type" => "application/json"}, ["{\"errcode\":\"M_LIMIT_EXCEEDED\"}"])
    end

    # The retry inherited from `Async::REST::Wrapper::Generic` would send the request the resource has already mutated a second time, so it is disabled here: {Async::Matrix::Middleware::RateLimited} does the waiting, below the resource.
    it "sends the request once and leaves the waiting to the middleware" do
      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError
        # Expected.
      end

      expect(delegate.requests).to be == 1
    end
  end
  with "a refusal which is a challenge" do
    let(:delegate) do
      RefusingDelegate.new(401, {"content-type" => "application/json"},
        ["{\"session\":\"a-session\",\"flows\":[{\"stages\":[\"m.login.password\"]}],\"params\":{}}"])
    end

    # A body naming flows and a session is the homeserver asking, not refusing.
    it "raises the challenge rather than a plain refusal" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::InteractiveAuthenticationError => raised
        error = raised
      end

      expect(error).not.to be_nil
      expect(error.session).to be == "a-session"
      expect(error).to be(:accepts?, "m.login.password")
    end
  end

  with "a refusal whose body is not JSON" do
    let(:delegate) {RefusingDelegate.new(502, {"content-type" => "text/html"}, ["<html>502</html>"])}

    # The status is still meaningful, and the body is reported as it stands.
    it "raises a plain refusal carrying the body" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => raised
        error = raised
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.status).to be == 502
      expect(error.message).to be(:include?, "502")
    end
  end
end
