# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_terms"

describe Async::Matrix::Identity::V2Terms do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # No authentication is required to read them: a user decides whether to accept before they have an account.
  it "can getTerms" do
    policies = unauthenticated.v2_terms.get_terms

    expect(policies.names).to be(:include?, :terms_of_service)
    expect(policies.policies[:terms_of_service][:version]).to be_a(String)
  end

  it "can agreeToTerms" do
    session = unauthenticated.authenticated(registered.token)

    expect(session.v2_terms.agree_to_terms([terms]).value).to be == {}
  end

  # Sydent answers every other authenticated operation `M_TERMS_NOT_SIGNED` until the terms are signed, which is what makes them worth asking for.
  it "refuses the rest until they are signed" do
    session = unauthenticated.authenticated(registered.token)

    error = nil

    begin
      session.v2_auth.get_account
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_TERMS_NOT_SIGNED"
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2Terms::CASES
end
