# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "sus/fixtures/async/reactor_context"

require "async/matrix/authenticated"
require "async/matrix/credentials"

require "protocol/http/middleware"

# Issues a new token each time it is asked, the way the homeserver does.
class TokenIssuer
  def initialize
    @attempts = 0
  end

  attr :attempts

  def refresh(refresh_token)
    @attempts += 1

    Issued.new(@attempts, 300_000)
  end

  Issued = Struct.new(:attempt, :expires_in_ms) do
    def access_token = "replacement-#{self.attempt}"

    def refresh_token = "refresh-#{self.attempt}"
  end
end

# Rejects the first request and answers the rest, recording each one as it arrived.
class RejectingDelegate < ::Protocol::HTTP::Middleware
  def initialize(errcode: "M_UNKNOWN_TOKEN", rejections: 1)
    super(nil)

    @errcode = errcode
    @rejections = rejections
    @requests = []
  end

  # @attribute [Array(Hash)] what each request carried when it arrived.
  attr :requests

  def call(request)
    @requests << {
      authorization: request.headers.to_a.select{|key, _| key == "authorization"}.map(&:last),
      body: request.body&.join,
    }

    if @requests.size <= @rejections
      ::Protocol::HTTP::Response[401, {"content-type" => "application/json"}, ["{\"errcode\":\"#{@errcode}\"}"]]
    else
      ::Protocol::HTTP::Response[200, {"content-type" => "application/json"}, ["{\"ok\":true}"]]
    end
  end

  def close
  end
end

describe Async::Matrix::Authenticated do
  include Sus::Fixtures::Async::ReactorContext

  let(:issuer) {TokenIssuer.new}

  let(:delegate) {RejectingDelegate.new}

  let(:credentials) {Async::Matrix::Credentials.new(issuer, access_token: "first", refresh_token: "refresh-0")}

  let(:authenticated) {subject.new(delegate, credentials)}

  def get
    authenticated.call(::Protocol::HTTP::Request["GET", "/_matrix/client/v3/account/whoami"])
  end

  with "a request the homeserver accepts" do
    let(:delegate) {RejectingDelegate.new(rejections: 0)}

    it "authenticates it" do
      get

      expect(delegate.requests.first[:authorization]).to be == ["Bearer first"]
    end

    # `merge` would add a second authorization header, which a homeserver rejects.
    it "replaces an authorization header the resource already supplied" do
      request = ::Protocol::HTTP::Request["GET", "/", Protocol::HTTP::Headers[{"authorization" => "Bearer stale"}]]

      authenticated.call(request)

      expect(delegate.requests.first[:authorization]).to be == ["Bearer first"]
    end
  end

  with "a rejected access token" do
    it "replaces it and makes the request again" do
      response = get

      expect(response.status).to be == 200
      expect(delegate.requests.size).to be == 2
    end

    it "makes the second request with the new token" do
      get

      first, second = delegate.requests

      expect(first[:authorization]).to be == ["Bearer first"]
      expect(second[:authorization]).to be == ["Bearer replacement-1"]
    end

    it "replays the body" do
      request = ::Protocol::HTTP::Request["POST", "/", {}, ::Protocol::HTTP::Body::Buffered.wrap("{\"a\":1}")]

      authenticated.call(request)

      first, second = delegate.requests

      expect(first[:body]).to be == "{\"a\":1}"
      expect(second[:body]).to be == first[:body]
    end
  end

  with "nothing to replace the access token with" do
    let(:credentials) {Async::Matrix::Credentials.new(issuer, access_token: "first")}

    # The caller is told the token was rejected, rather than being given a renewal it never asked for.
    it "reports the rejection" do
      response = get

      expect(response.status).to be == 401
      expect(delegate.requests.size).to be == 1
      expect(issuer.attempts).to be == 0
    end
  end

  with "a rejection which is not about the access token" do
    let(:delegate) {RejectingDelegate.new(errcode: "M_FORBIDDEN")}

    # A protected endpoint answers 401 with the authentication flows it wants, which is the caller's business.
    it "reports it rather than renewing" do
      response = get

      expect(response.status).to be == 401
      expect(delegate.requests.size).to be == 1
      expect(issuer.attempts).to be == 0
    end
  end

  with "a token which is rejected twice" do
    let(:delegate) {RejectingDelegate.new(rejections: 2)}

    # One renewal per request, so that a homeserver which rejects everything cannot be asked forever.
    it "tries once and then reports it" do
      response = get

      expect(response.status).to be == 401
      expect(delegate.requests.size).to be == 2
      expect(issuer.attempts).to be == 1
    end
  end
end
