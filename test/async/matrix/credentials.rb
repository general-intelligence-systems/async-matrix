# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "sus/fixtures/async/reactor_context"

require "async/matrix/credentials"
require "async/matrix/error"

# The tokens a refresh issued, named after the attempt which issued them.
Issued = Struct.new(:attempt, :expires_in_ms) do
  def access_token = "access-#{self.attempt}"

  def refresh_token = "refresh-#{self.attempt}"
end

# Stands in for the homeserver's refresh endpoint, counting how often it is asked.
class Issuer
  def initialize(expires_in_ms: 300_000)
    @expires_in_ms = expires_in_ms
    @attempts = 0
  end

  attr :attempts

  def refresh(refresh_token)
    @attempts += 1

    Issued.new(@attempts, @expires_in_ms)
  end
end

# Refuses every refresh, the way a homeserver does once the refresh token is spent.
class Refuser
  def initialize(status: 401, errcode: "M_UNKNOWN_TOKEN")
    @status = status
    @errcode = errcode
    @attempts = 0
  end

  attr :attempts

  def refresh(refresh_token)
    @attempts += 1

    raise Async::Matrix::RequestError.new(@status, @errcode, "refused")
  end
end

describe Async::Matrix::Credentials do
  include Sus::Fixtures::Async::ReactorContext

  let(:issuer) {Issuer.new}

  let(:credentials) {subject.new(issuer, access_token: "first", refresh_token: "refresh-0")}

  with "#authorization" do
    it "carries the access token and its generation" do
      expect(credentials.authorization).to be == ["Bearer first", 0]
    end
  end

  with "#renewable?" do
    it "is renewable with a refresh token" do
      expect(credentials).to be(:renewable?)
    end

    it "is not renewable without one" do
      expect(subject.new(issuer, access_token: "first")).not.to be(:renewable?)
    end
  end

  with "#expiring?" do
    it "is not expiring when the homeserver did not say" do
      expect(subject.new(issuer, access_token: "first")).not.to be(:expiring?)
    end

    it "is expiring once it is within the margin" do
      expect(subject.new(issuer, access_token: "first", expires_in_ms: 1000)).to be(:expiring?)
    end

    it "is not expiring while there is more than the margin left" do
      lifetime = ((subject::MARGIN + 60) * 1000).to_i

      expect(subject.new(issuer, access_token: "first", expires_in_ms: lifetime)).not.to be(:expiring?)
    end
  end

  with "#renew!" do
    it "replaces the access token" do
      credentials.renew!

      expect(credentials.access_token).to be == "access-1"
      expect(credentials.generation).to be == 1
    end

    # The homeserver rotates the refresh token, so the next renewal must use the new one.
    it "adopts the new refresh token" do
      credentials.renew!

      expect(credentials.refresh_token).to be == "refresh-1"
    end

    it "records when the new access token expires" do
      credentials.renew!

      expect(credentials.expires_at).to be_a(Time)
    end

    # Whoever renewed first has already supplied a working token, so a later caller holding a stale one asks for nothing.
    it "does nothing when the token was already replaced" do
      credentials.renew!

      credentials.renew!(0)

      expect(issuer.attempts).to be == 1
      expect(credentials.generation).to be == 1
    end

    it "renews once for any number of concurrent callers" do
      8.times.map{Async{credentials.renew!(0)}}.each(&:wait)

      expect(issuer.attempts).to be == 1
      expect(credentials.generation).to be == 1
    end

    it "reports a refusal as an authentication error" do
      refused = subject.new(Refuser.new, access_token: "first", refresh_token: "refresh-0")

      expect{refused.renew!}.to raise_exception(Async::Matrix::AuthenticationError)
    end

    # Logging out invalidates the refresh token too, so a caller which already handles a rejected access token handles a failed replacement without knowing it happened.
    it "reports a refusal as a request error too" do
      refused = subject.new(Refuser.new, access_token: "first", refresh_token: "refresh-0")

      error = nil

      begin
        refused.renew!
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:unknown_token?)
      expect(error.status).to be == 401
    end
  end

  with "an expiring access token" do
    let(:credentials) {subject.new(issuer, access_token: "first", refresh_token: "refresh-0", expires_in_ms: 1000)}

    it "replaces it before the request is made" do
      expect(credentials.authorization).to be == ["Bearer access-1", 1]
    end
  end

  with "an expiring access token and nothing to replace it with" do
    let(:credentials) {subject.new(issuer, access_token: "first", expires_in_ms: 1000)}

    # There is nothing to be done about it, so the request is made and the homeserver decides.
    it "sends it anyway" do
      expect(credentials.authorization).to be == ["Bearer first", 0]
      expect(issuer.attempts).to be == 0
    end
  end

  with "a refusal the homeserver may recover from" do
    # A server error is the homeserver having a bad moment. Reporting it as an authentication error would have a caller discard a session which is still good.
    it "reports a server error as it stands" do
      refused = subject.new(Refuser.new(status: 502, errcode: "M_UNKNOWN"), access_token: "first", refresh_token: "refresh-0")

      error = nil

      begin
        refused.renew!
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).not.to be_a(Async::Matrix::AuthenticationError)
      expect(error.status).to be == 502
    end

    # A rate limit is the homeserver asking us to wait, not a verdict on the refresh token.
    it "reports a rate limit as it stands" do
      refused = subject.new(Refuser.new(status: 429, errcode: "M_LIMIT_EXCEEDED"), access_token: "first", refresh_token: "refresh-0")

      error = nil

      begin
        refused.renew!
      rescue Async::Matrix::RequestError => error
      end

      expect(error).not.to be_a(Async::Matrix::AuthenticationError)
      expect(error.status).to be == 429
    end

    # It may work next time, so nothing is remembered.
    it "will try again" do
      refuser = Refuser.new(status: 502, errcode: "M_UNKNOWN")
      refused = subject.new(refuser, access_token: "first", refresh_token: "refresh-0")

      2.times do
        begin
          refused.renew!
        rescue Async::Matrix::RequestError
          nil
        end
      end

      expect(refuser.attempts).to be == 2
    end
  end

  with "a refusal which ends the session" do
    let(:refuser) {Refuser.new}

    let(:credentials) {subject.new(refuser, access_token: "first", refresh_token: "refresh-0")}

    # The refresh token is spent, so asking again cannot help and would only hammer the homeserver.
    it "asks once however many callers are waiting" do
      8.times.map do
        Async do
          begin
            credentials.renew!(0)
          rescue Async::Matrix::AuthenticationError
            nil
          end
        end
      end.each(&:wait)

      expect(refuser.attempts).to be == 1
    end

    it "reports the same refusal to every caller" do
      errors = 8.times.map do
        Async do
          begin
            credentials.renew!(0)
          rescue Async::Matrix::AuthenticationError => error
            error
          end
        end
      end.map(&:wait)

      expect(errors.map(&:class).uniq).to be == [Async::Matrix::AuthenticationError]
      expect(errors.map(&:status).uniq).to be == [401]
    end
  end
end
