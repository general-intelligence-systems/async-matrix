# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/session"

describe Async::Matrix::ClientServer::Login do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Session::CASES

  with "#login" do
    it "carries the identity it logged in as" do
      login = unauthenticated.login(username, Async::Matrix::TEST_PASSWORD)

      expect(login.user_id).to be == self.user_id
      expect(login.access_token).to be_a(String)
      expect(login.device_id).to be_a(String)
    end

    it "fails with an unknown login type" do
      error = nil

      begin
        unauthenticated.login(username, Async::Matrix::TEST_PASSWORD, type: "m.login.nonsense")
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
    end
  end

  with "#logged_in" do
    it "derives a client which is authenticated" do
      expect(client.get_token_owner.user_id).to be == self.user_id
    end
  end

  with "#logout" do
    it "invalidates the access token it was called with" do
      session = self.account("logout-#{SecureRandom.hex(4)}")

      session.logout

      error = nil

      begin
        session.get_token_owner.user_id
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error).to be(:unknown_token?)
    end
  end
end
