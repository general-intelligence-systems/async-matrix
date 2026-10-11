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
end
