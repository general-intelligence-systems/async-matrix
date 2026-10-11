# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "sus/fixtures/async/reactor_context"

require "async/matrix"

# Answers a 429 first and a 200 after, recording each request as it arrived.
class RateLimitedDelegate < Protocol::HTTP::Middleware
  def initialize(retry_after: {"retry-after" => "0"}, body: ["rate limited"])
    super(nil)

    @requests = []
    @responses = [
      Protocol::HTTP::Response[429, retry_after, body],
      Protocol::HTTP::Response[200, {"content-type" => "application/json"}, ["{\"ok\":true}"]],
    ]
  end

  attr :requests

  def call(request)
    @requests << {
      path: request.path,
      authorization: request.headers.to_a.select{|key, _| key == "authorization"}.map(&:last),
    }

    @responses.shift
  end

  def close
  end
end

# Answers 429 to everything, as a homeserver under sustained load does.
class AlwaysRateLimitedDelegate < Protocol::HTTP::Middleware
  def initialize
    super(nil)

    @requests = 0
  end

  # @attribute [Integer] how many requests arrived.
  attr :requests

  def call(request)
    @requests += 1

    Protocol::HTTP::Response[429, {"retry-after" => "0", "content-type" => "application/json"}, ["{\"errcode\":\"M_LIMIT_EXCEEDED\",\"error\":\"Too Many Requests\",\"retry_after_ms\":0}"]]
  end

  def close
  end
end

describe Async::Matrix::Wrapper do
  include Sus::Fixtures::Async::ReactorContext

  let(:delegate) {RateLimitedDelegate.new}

  let(:reference) {Protocol::URL::Reference.parse("/_matrix/client/v3/sync").with(parameters: {timeout: 0})}

  let(:headers) {Protocol::HTTP::Headers[{"authorization" => "Bearer secret"}]}

  let(:resource) {Async::Matrix::ClientServer::Client.new(delegate, reference, headers)}

  with "a rate limited request" do
    it "retries it" do
      Async::Matrix::Representation.get(resource)

      expect(delegate.requests.size).to be == 2
    end

    # The resource mutates the request it is given, so a retry builds a fresh one.
    it "sends an equivalent request when it retries" do
      Async::Matrix::Representation.get(resource)

      first, second = delegate.requests

      expect(second[:path]).to be == first[:path]
      expect(second[:authorization]).to be == first[:authorization]
    end
  end

  with "a rate limit longer than it will wait" do
    let(:delegate) do
      RateLimitedDelegate.new(
        retry_after: {"content-type" => "application/json"},
        body: ["{\"errcode\":\"M_LIMIT_EXCEEDED\",\"retry_after_ms\":600000}"],
      )
    end

    it "reports it rather than waiting" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:limit_exceeded?)
      expect(delegate.requests.size).to be == 1
    end
  end

  with "a rate limit which names no delay" do
    let(:delegate) do
      RateLimitedDelegate.new(
        retry_after: {"content-type" => "application/json"},
        body: ["{\"errcode\":\"M_FORBIDDEN\",\"error\":\"no\"}"],
      ).tap do |delegate|
        delegate.requests.clear
      end
    end

    # Without a `retry-after` there is nothing to wait for, so the response is reported as it is.
    it "raises with the code the body gave" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => error
      end

      expect(error.errcode).to be == "M_FORBIDDEN"
      expect(error.status).to be == 429
    end
  end

  with "a rate limit which never lifts" do
    let(:delegate) {AlwaysRateLimitedDelegate.new}

    # {MAXIMUM_RETRY_DELAY} bounds one wait, not the total, so a server answering `retry-after: 0` forever would spin here.
    it "stops after the maximum number of attempts" do
      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError
        # The rate limit, reported rather than retried.
      end

      expect(delegate.requests).to be == Async::Matrix::Wrapper::MAXIMUM_ATTEMPTS
    end

    it "reports the rate limit to the caller" do
      error = nil

      begin
        Async::Matrix::Representation.get(resource)
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:limit_exceeded?)
      expect(error.status).to be == 429
    end
  end

  it "waits no longer than its maximum" do
    expect(subject::MAXIMUM_RETRY_DELAY).to be == 30.0
  end

  it "sends a request no more times than its maximum" do
    expect(subject::MAXIMUM_ATTEMPTS).to be == 3
  end
end
