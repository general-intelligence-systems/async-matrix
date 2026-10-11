# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/http/body/buffered"
require "protocol/http/request"
require "protocol/http/response"

require "sus/fixtures/async/reactor_context"

require "async/matrix/middleware/rate_limited"

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
    @requests << {path: request.path, body: request.body&.join}

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

describe Async::Matrix::Middleware::RateLimited do
  include Sus::Fixtures::Async::ReactorContext

  let(:delegate) {RateLimitedDelegate.new}
  let(:middleware) {subject.new(delegate)}
  let(:request) {Protocol::HTTP::Request["GET", "/_matrix/client/v3/sync"]}

  with "a rate limited request" do
    it "sends it again" do
      response = middleware.call(request)

      expect(response.status).to be == 200
      expect(delegate.requests.size).to be == 2
    end

    it "sends the same path both times" do
      middleware.call(request)

      expect(delegate.requests.map{|each| each[:path]}).to be == ["/_matrix/client/v3/sync", "/_matrix/client/v3/sync"]
    end

    it "replays the body" do
      body = Protocol::HTTP::Body::Buffered.new(["payload"])
      post = Protocol::HTTP::Request["POST", "/_matrix/client/v3/createRoom", nil, body]

      middleware.call(post)

      expect(delegate.requests.map{|each| each[:body]}).to be == ["payload", "payload"]
    end
  end

  with "a body which cannot be replayed" do
    it "reports the rate limit rather than sending it again" do
      body = Protocol::HTTP::Body::Buffered.new(["payload"])
      mock(body) do |mocked|
        mocked.replace(:rewindable?){false}
      end

      response = middleware.call(Protocol::HTTP::Request["POST", "/x", nil, body])

      expect(response.status).to be == 429
      expect(delegate.requests.size).to be == 1
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
      response = middleware.call(request)

      expect(response.status).to be == 429
      expect(delegate.requests.size).to be == 1
    end

    it "leaves the body readable by the caller" do
      response = middleware.call(request)

      expect(response.read).to be(:include?, "M_LIMIT_EXCEEDED")
    end
  end

  with "a rate limit which names no delay" do
    let(:delegate) do
      RateLimitedDelegate.new(
        retry_after: {"content-type" => "application/json"},
        body: ["{\"errcode\":\"M_LIMIT_EXCEEDED\"}"],
      )
    end

    it "reports it rather than guessing" do
      response = middleware.call(request)

      expect(response.status).to be == 429
      expect(delegate.requests.size).to be == 1
    end
  end

  with "a rate limit which never lifts" do
    let(:delegate) {AlwaysRateLimitedDelegate.new}

    it "stops after the maximum number of attempts" do
      response = middleware.call(request)

      expect(response.status).to be == 429
      expect(delegate.requests).to be == subject::MAXIMUM_ATTEMPTS
    end
  end

  with "#retry_after_duration" do
    let(:durations) do
      middleware.tap do |object|
        object.singleton_class.send(:public, :retry_after_duration)
      end
    end

    it "reads a number of seconds" do
      expect(durations.retry_after_duration("123")).to be == 123
    end

    # A date which has passed asks for no wait at all, rather than a negative one.
    it "reads a date which has passed as no wait" do
      expect(durations.retry_after_duration(Time.now.httpdate)).to be == 0.0
    end

    it "reads a date in the future as the time until it" do
      expect(durations.retry_after_duration((Time.now + 60).httpdate)).to be > 0.0
    end

    # Neither a date nor a number: `to_f` reads it as no wait, which is sent again at once.
    it "reads something which is neither as no wait" do
      expect(durations.retry_after_duration("soon")).to be == 0.0
    end
  end

  it "waits no longer than its maximum" do
    expect(subject::MAXIMUM_RETRY_DELAY).to be == 30.0
  end

  it "sends a request no more times than its maximum" do
    expect(subject::MAXIMUM_ATTEMPTS).to be == 3
  end
end
