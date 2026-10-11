# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_pubkey"

describe Async::Matrix::Identity::V2Pubkey do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # No authentication is required: the keys are what a signature is checked against.
  it "can getPubKeyV2" do
    expect(unauthenticated.v2_pubkey.get_pub_key_v2("ed25519:0").public_key).to be_a(String)
  end

  it "can isPubKeyValidV2" do
    key = unauthenticated.v2_pubkey.get_pub_key_v2("ed25519:0").public_key

    expect(unauthenticated.v2_pubkey.is_pub_key_valid_v2(key)).to be(:valid?)
  end

  it "can isEphemeralPubKeyValidV2" do
    expect(unauthenticated.v2_pubkey.is_ephemeral_pub_key_valid_v2("not-a-key")).not.to be(:valid?)
  end

  it "does not vouch for a key it has never used" do
    expect(unauthenticated.v2_pubkey.is_pub_key_valid_v2("not-a-key")).not.to be(:valid?)
  end

  it "fails for a key it has no record of" do
    expect do
      unauthenticated.v2_pubkey.get_pub_key_v2("ed25519:nope")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2Pubkey::CASES
end
