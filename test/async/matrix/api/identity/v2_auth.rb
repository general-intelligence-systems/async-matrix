# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_auth"

describe Async::Matrix::Identity::V2Auth do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # An identity server has no accounts of its own: the homeserver vouches for the user with an OpenID token, which the identity server verifies by asking that homeserver over federation.
  it "can registerAccount" do
    expect(registered.token).to be_a(String)
  end

  it "can getAccount" do
    expect(identity.v2_auth.get_account.user_id).to be == self.user_id
  end

  it "can logout" do
    session = identity

    expect(session.v2_auth.logout.value).to be == {}
  end

  # The token is gone once it is logged out, which is what logging out is for.
  it "answers for nobody once the token is logged out" do
    session = identity
    session.v2_auth.logout

    error = nil

    begin
      session.v2_auth.get_account
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_UNAUTHORIZED"
  end

  # A token the homeserver never issued is one it will not vouch for.
  it "refuses a token the homeserver did not issue" do
    expect do
      unauthenticated.v2_auth.register_account("not-a-token", "Bearer", "localhost", 3600)
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2Auth::CASES
end
