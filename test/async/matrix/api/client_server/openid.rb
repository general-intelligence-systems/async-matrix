# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/openid"

describe Async::Matrix::ClientServer::OpenID do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can requestOpenIdToken" do
    token = client.openid.request_open_id_token(self.user_id)

    expect(token.access_token).to be_a(String)
    expect(token.token_type).to be == "Bearer"
    expect(token.matrix_server_name).to be == "localhost"
    expect(token.expires_in).to be > 0
  end

  # The token is this user's to give out, so the homeserver will not make one for anybody else.
  it "refuses a token for another user" do
    expect do
      client.openid.request_open_id_token("@someone-else:localhost")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::OpenID::CASES
end
