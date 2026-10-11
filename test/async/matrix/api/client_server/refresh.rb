# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Refresh do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # Asked for explicitly: `#login` does not request one by default, because it shortens the access token.
  let(:login) {unauthenticated.login(username, Async::Matrix::TEST_PASSWORD, refresh_token: true)}

  it "can refresh" do
    refreshed = unauthenticated.refresh.refresh(login.refresh_token)

    expect(refreshed.access_token).to be_a(String)
  end

  with "#refresh" do
    it "issues a token which authenticates a request" do
      refreshed = unauthenticated.refresh.refresh(login.refresh_token)

      session = unauthenticated.authenticated(refreshed.access_token)

      expect(session.get_token_owner.user_id).to be == self.user_id
    end

    # The homeserver rotates the refresh token, so the next renewal uses the new one.
    it "rotates the refresh token" do
      refreshed = unauthenticated.refresh.refresh(login.refresh_token)

      expect(refreshed.refresh_token).to be_a(String)
      expect(refreshed.refresh_token).not.to be == login.refresh_token
    end

    it "reports how long the new access token lasts" do
      refreshed = unauthenticated.refresh.refresh(login.refresh_token)

      expect(refreshed.expires_in_ms).to be > 0
    end

    it "fails with a refresh token the homeserver does not know" do
      error = nil

      begin
        unauthenticated.refresh.refresh("syr_not_a_real_token")
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:unknown_token?)
    end
  end

  with "a client whose access token the homeserver rejects" do
    let(:session) {unauthenticated.authenticated("syt_not_a_real_token", refresh_token: login.refresh_token)}

    it "replaces the access token and makes the request again" do
      expect(session.get_token_owner.user_id).to be == self.user_id
      expect(session.delegate.credentials.generation).to be == 1
    end

    # A write has a body, which has already been read in order to send it once.
    it "replays the body of a write" do
      room = session.create_room(name: Async::Matrix::TEST_ROOM_NAME)

      expect(room.id).to be =~ /\A!/
    end

    it "renews once however many requests are in flight" do
      # Resolved before the tasks start: a `let` is not fiber safe, so eight fibers racing to be the first to log in would each log in for themselves.
      credentials = session.delegate.credentials

      owners = 8.times.map{Async{session.get_token_owner.user_id}}.map(&:wait)

      expect(owners.uniq).to be == [self.user_id]
      expect(credentials.generation).to be == 1
    end
  end

  with "#logged_in" do
    # Logging in asks for a refresh token, so the session can renew itself without a second login.
    it "derives a client which can renew its own access token" do
      credentials = client.delegate.credentials

      expect(credentials).to be(:renewable?)
      expect(credentials.expires_at).to be_a(Time)
    end
  end
end
