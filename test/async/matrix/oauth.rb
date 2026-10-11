# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "base64"
require "digest"

require "sus/fixtures/async/reactor_context"

require "async/matrix/oauth"
require "async/matrix/credentials"

# Stands in for the authorization server, recording what each request carried.
class FakeAuthorizationServer < ::Protocol::HTTP::Middleware
  def initialize(status: 200, body: nil)
    super(nil)

    @status = status
    @body = body
    @requests = []
  end

  # @attribute [Array(Hash)] what each request carried when it arrived.
  attr :requests

  def call(request)
    @requests << {
      path: request.path,
      content_type: request.headers["content-type"],
      body: request.body&.join,
    }

    ::Protocol::HTTP::Response[@status, {"content-type" => "application/json"}, [@body || "{}"]]
  end

  def close
  end
end

# The metadata the homeserver would have published.
FakeMetadata = Struct.new(:issuer, :authorization_endpoint, :token_endpoint, :registration_endpoint)

describe Async::Matrix::OAuth do
  include Sus::Fixtures::Async::ReactorContext

  let(:metadata) do
    FakeMetadata.new(
      "http://localhost:8091/",
      "http://localhost:8091/authorize",
      "http://localhost:8091/oauth2/token",
      "http://localhost:8091/oauth2/registration",
    )
  end

  let(:delegate) {FakeAuthorizationServer.new}

  let(:resource) {Async::REST::Resource.new(delegate)}

  let(:server) {Async::Matrix::OAuth::AuthorizationServer.new(resource, metadata)}

  let(:verifier) {Async::Matrix::OAuth::Verifier.new("a-known-verifier")}

  with Async::Matrix::OAuth::Verifier do
    it "derives the challenge as the unpadded SHA-256 of the verifier" do
      expected = Base64.urlsafe_encode64(Digest::SHA256.digest("a-known-verifier"), padding: false)

      expect(verifier.challenge).to be == expected
    end

    it "does not pad the challenge" do
      expect(verifier.challenge).not.to be(:include?, "=")
    end

    it "reports the method the challenge was derived with" do
      expect(verifier.method).to be == "S256"
    end

    it "generates a different verifier each time" do
      verifiers = 4.times.map{Async::Matrix::OAuth::Verifier.generate.verifier}

      expect(verifiers.uniq.size).to be == 4
    end

    # RFC 7636 wants between 43 and 128 characters.
    it "generates a verifier of a permitted length" do
      length = Async::Matrix::OAuth::Verifier.generate.verifier.size

      expect(length).to be >= 43
      expect(length).to be <= 128
    end
  end

  with "#authorization_url" do
    let(:url) do
      server.authorization_url(
        client_id: "a-client",
        redirect_uri: "http://127.0.0.1:1234/",
        verifier: verifier,
        scope: "a-scope",
        state: "a-state",
      )
    end

    let(:parameters) {::Protocol::URL::Encoding.decode(url.split("?", 2).last)}

    it "is built on the endpoint the metadata named" do
      expect(url).to be(:start_with?, "http://localhost:8091/authorize?")
    end

    it "asks for a code" do
      expect(parameters["response_type"]).to be == "code"
    end

    it "carries the client, the redirect and the scope" do
      expect(parameters["client_id"]).to be == "a-client"
      expect(parameters["redirect_uri"]).to be == "http://127.0.0.1:1234/"
      expect(parameters["scope"]).to be == "a-scope"
      expect(parameters["state"]).to be == "a-state"
    end

    # A public client has no secret, so the challenge is what proves it is the same client later.
    it "carries the challenge rather than the verifier" do
      expect(parameters["code_challenge"]).to be == verifier.challenge
      expect(parameters["code_challenge_method"]).to be == "S256"
      expect(url).not.to be(:include?, "a-known-verifier")
    end
  end

  with "#exchange" do
    let(:delegate) do
      FakeAuthorizationServer.new(body: "{\"access_token\":\"an-access-token\",\"refresh_token\":\"a-refresh-token\",\"token_type\":\"Bearer\",\"expires_in\":300}")
    end

    let(:tokens) do
      server.exchange("a-code", client_id: "a-client", redirect_uri: "http://127.0.0.1:1234/", verifier: verifier)
    end

    it "posts to the token endpoint" do
      tokens

      expect(delegate.requests.first[:path]).to be == "/oauth2/token"
    end

    # The token endpoint takes a form, not JSON.
    it "sends a form" do
      tokens

      expect(delegate.requests.first[:content_type]).to be == "application/x-www-form-urlencoded"
    end

    it "redeems the code with the verifier" do
      tokens

      form = ::Protocol::URL::Encoding.decode(delegate.requests.first[:body])

      expect(form["grant_type"]).to be == "authorization_code"
      expect(form["code"]).to be == "a-code"
      expect(form["code_verifier"]).to be == "a-known-verifier"
      expect(form["client_id"]).to be == "a-client"
    end

    it "reports the tokens it was issued" do
      expect(tokens.access_token).to be == "an-access-token"
      expect(tokens.refresh_token).to be == "a-refresh-token"
      expect(tokens.token_type).to be == "Bearer"
    end

    # OAuth reports a lifetime in seconds where Matrix reports milliseconds.
    it "converts the lifetime to milliseconds" do
      expect(tokens.expires_in).to be == 300
      expect(tokens.expires_in_ms).to be == 300_000
    end
  end

  with "#refresh" do
    let(:delegate) do
      FakeAuthorizationServer.new(body: "{\"access_token\":\"a-new-token\",\"expires_in\":300}")
    end

    it "exchanges the refresh token" do
      server.refresh("a-refresh-token", client_id: "a-client")

      form = ::Protocol::URL::Encoding.decode(delegate.requests.first[:body])

      expect(form["grant_type"]).to be == "refresh_token"
      expect(form["refresh_token"]).to be == "a-refresh-token"
      expect(form["client_id"]).to be == "a-client"
    end

    # The authorization server may omit a new refresh token, which leaves the old one standing.
    it "reports no refresh token when none was issued" do
      expect(server.refresh("a-refresh-token", client_id: "a-client").refresh_token).to be_nil
    end
  end

  with "#register" do
    let(:delegate) {FakeAuthorizationServer.new(body: "{\"client_id\":\"a-client\"}")}

    it "posts the client metadata as JSON" do
      registration = server.register(client_name: "async-matrix", application_type: "native")

      expect(registration.client_id).to be == "a-client"
      expect(delegate.requests.first[:path]).to be == "/oauth2/registration"
      expect(delegate.requests.first[:content_type]).to be == "application/json"
    end
  end

  with "a refusal" do
    let(:delegate) do
      FakeAuthorizationServer.new(status: 400, body: "{\"error\":\"invalid_grant\",\"error_description\":\"The provided access grant is invalid.\"}")
    end

    it "reports the OAuth error code" do
      error = nil

      begin
        server.refresh("a-spent-token", client_id: "a-client")
      rescue Async::Matrix::OAuth::Error => error
      end

      expect(error).to be_a(Async::Matrix::OAuth::Error)
      expect(error).to be(:invalid_grant?)
      expect(error.status).to be == 400
    end

    # A caller which already handles a refusal from the homeserver handles this one too.
    it "is a request error" do
      expect{server.refresh("a-spent-token", client_id: "a-client")}.to raise_exception(Async::Matrix::RequestError)
    end
  end

  with "an endpoint on another host" do
    let(:metadata) do
      FakeMetadata.new("http://localhost:8091/", "http://localhost:8091/authorize", "http://elsewhere:9999/token", nil)
    end

    # Every endpoint is reached through the one connection, so one on another host cannot be used.
    it "refuses to use it" do
      expect{server.refresh("a-token", client_id: "a-client")}.to raise_exception(Async::Matrix::OAuth::Error)
    end
  end

  with Async::Matrix::OAuth::Issuer do
    let(:delegate) do
      FakeAuthorizationServer.new(body: "{\"access_token\":\"a-renewed-token\",\"refresh_token\":\"a-new-refresh-token\",\"expires_in\":300}")
    end

    let(:issuer) {Async::Matrix::OAuth::Issuer.new(server, "a-client")}

    it "renews with the client the tokens were issued to" do
      issuer.refresh("a-refresh-token")

      form = ::Protocol::URL::Encoding.decode(delegate.requests.first[:body])

      expect(form["client_id"]).to be == "a-client"
    end

    # The issuer is what makes the credentials renewable, without them knowing it is OAuth.
    it "drives a renewal through the credentials" do
      credentials = Async::Matrix::Credentials.new(issuer, access_token: "first", refresh_token: "a-refresh-token")

      credentials.renew!

      expect(credentials.access_token).to be == "a-renewed-token"
      expect(credentials.refresh_token).to be == "a-new-refresh-token"
      expect(credentials.expires_at).to be_a(Time)
      expect(credentials.generation).to be == 1
    end
  end
end
