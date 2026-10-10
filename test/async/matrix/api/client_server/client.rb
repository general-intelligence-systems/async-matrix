# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Client do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  with "#versions" do
    it "can be read without authentication" do
      versions = unauthenticated.versions.value[:versions]

      expect(versions).to be_a(Array)
      expect(versions).not.to be(:empty?)
    end
  end

  with "#whoami" do
    it "reports the authenticated user" do
      expect(client.whoami.user_id).to be == self.user_id
    end

    it "fails without an access token" do
      error = nil

      begin
        unauthenticated.whoami.user_id
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
        invalid.whoami.user_id
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.errcode).to be == "M_UNKNOWN_TOKEN"
    end
  end

  with "an unknown room" do
    it "raises a request error" do
      error = nil

      begin
        client.room("!nonexistent:localhost").state.to_a
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
        client.join("#no-such-alias:localhost")
      rescue Async::Matrix::RequestError => error
      end

      expect(error).to be_a(Async::Matrix::RequestError)
      expect(error.status).to be == 404
    end
  end
end
