# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_phone_associations"

describe Async::Matrix::Identity::V2PhoneAssociations do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # The rig has no way to send a message, so the server cannot send a token for the user to read.
  it "can msisdnRequestTokenV2" do
    expect do
      identity.v2_phone_associations.msisdn_request_token_v2("a-secret", "GB", "7700900000")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The link is followed by a browser, so the answer is a page whether the server managed it or not.
  it "can msisdnSubmitTokenGetV2" do
    expect do
      unauthenticated.v2_phone_associations.msisdn_submit_token_get_v2("a-session", "a-secret", "a-token")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # A session which was never opened is not one a token can be submitted to.
  it "can msisdnSubmitTokenPostV2" do
    expect do
      identity.v2_phone_associations.msisdn_submit_token_post_v2("a-session", "a-secret", "a-token")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2PhoneAssociations::CASES
end
