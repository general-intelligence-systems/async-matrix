# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/client"

# Records what each request carried, and sends it to the homeserver all the same.
class RecordingDelegate < Protocol::HTTP::Middleware
  def initialize(delegate)
    super(delegate)

    @sent = []
  end

  # @attribute [Array(Hash)] the headers of each request, as the homeserver received them.
  attr :sent

  def call(request)
    @sent << request.headers.to_h

    super
  end
end

describe Async::Matrix::ClientServer::Client do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Client::CASES

  with "#with_credentials" do
    let(:credentials) {Async::Matrix::Credentials.new(nil, access_token: "a-token")}

    it "derives a client which authenticates with them" do
      authenticated = unauthenticated.with_credentials(credentials)

      expect(authenticated.delegate).to be_a(Async::Matrix::Middleware::Authenticated)
      expect(authenticated.delegate.credentials).to be_equal(credentials)
    end

    # The token goes below the resource, so it is not copied into every resource derived from this one.
    it "keeps the token out of the headers it derives" do
      authenticated = unauthenticated.with_credentials(credentials)

      expect(authenticated.headers["authorization"]).to be_nil
      expect(authenticated.with(path: "/x").headers["authorization"]).to be_nil
    end

    # Every resource derived from it shares the one holder, so a renewal reaches all of them.
    it "shares the credentials with every resource derived from it" do
      authenticated = unauthenticated.with_credentials(credentials)

      expect(authenticated.with(path: "/x").delegate.credentials).to be_equal(credentials)
    end
  end

  with ".login_token_from" do
    it "takes the token out of a redirect URL" do
      expect(subject.login_token_from("http://127.0.0.1:9999/cb?loginToken=abc123")).to be == "abc123"
    end

    it "ignores a fragment the server appended" do
      expect(subject.login_token_from("http://127.0.0.1:9999/cb?loginToken=abc123#")).to be == "abc123"
    end

    it "takes the token out of a bare query string" do
      expect(subject.login_token_from("?loginToken=abc123")).to be == "abc123"
    end

    it "refuses a redirect which carried no token" do
      expect do
        subject.login_token_from("http://127.0.0.1:9999/cb?error=denied")
      end.to raise_exception(Async::Matrix::RequestError)
    end
  end

  with "#versions" do
    it "can be read without authentication" do
      versions = unauthenticated.versions.value[:versions]

      expect(versions).to be_a(Array)
      expect(versions).not.to be(:empty?)
    end
  end

  with "#whoami" do
    it "reports the authenticated user" do
      expect(client.get_token_owner.user_id).to be == self.user_id
    end

    it "fails without an access token" do
      error = nil

      begin
        unauthenticated.get_token_owner.user_id
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:unknown_token?)
      expect(error.status).to be == 401
    end

    it "fails with an invalid access token" do
      invalid = unauthenticated.authenticated("syt_not_a_real_token")

      error = nil

      begin
        invalid.get_token_owner.user_id
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.errcode).to be == "M_UNKNOWN_TOKEN"
    end
  end

  with "the user agent" do
    let(:recorder) {RecordingDelegate.new(unauthenticated.delegate)}

    let(:recording) {subject[Async::Matrix::TEST_VERSION].new(recorder, unauthenticated.reference)}

    # It was sent only by `authenticated`, so the homeserver's own logs recorded `"-"` against every login.
    it "is sent on a request which is not authenticated" do
      recording.get_login_flows.flows

      expect(recorder.sent.last["user-agent"]).to be == Async::Matrix::ClientServer::Client::USER_AGENT
    end

    it "names the gem and its version" do
      recording.versions.value

      expect(recorder.sent.last["user-agent"]).to be == "async-matrix/#{Async::Matrix::VERSION}"
    end

    it "is sent alongside the authorization once authenticated" do
      self.account(username, through: recording).get_token_owner.user_id

      sent = recorder.sent.last

      expect(sent["user-agent"]).to be == Async::Matrix::ClientServer::Client::USER_AGENT
      expect(sent["authorization"]).to be(:start_with?, "Bearer ")
    end

    # A resource derived for a room or a representation must not lose it.
    it "is sent on a request made through a derived resource" do
      client = self.account(username, through: recording)
      room = client.create_room(name: "User agent")

      room.get_room_state.to_a

      expect(recorder.sent.last["user-agent"]).to be == Async::Matrix::ClientServer::Client::USER_AGENT
    end
  end

  with "an unknown room" do
    it "raises a request error" do
      error = nil

      begin
        client.room("!nonexistent:localhost").get_room_state.to_a
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.errcode).to be == "M_FORBIDDEN"
    end
  end

  with "an unknown alias" do
    it "raises a request error" do
      error = nil

      begin
        client.join_room("#no-such-alias:localhost")
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.status).to be == 404
    end
  end
end
