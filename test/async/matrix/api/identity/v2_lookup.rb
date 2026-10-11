# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

describe Async::Matrix::Identity::V2Lookup do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  it "can getHashDetails" do
    details = identity.v2_lookup.get_hash_details

    expect(details.lookup_pepper).to be_a(String)
    expect(details.algorithms).to be(:include?, "sha256")
  end

  it "can lookupUsersV2" do
    details = identity.v2_lookup.get_hash_details

    found = identity.v2_lookup.lookup_users_v2("none", details.lookup_pepper, ["nobody@example.com email"])

    expect(found).to be(:empty?)
  end

  # The pepper changes, so a lookup which quotes the wrong one is refused rather than answered.
  it "refuses a lookup which quotes the wrong pepper" do
    expect do
      identity.v2_lookup.lookup_users_v2("none", "not-the-pepper", ["nobody@example.com email"])
    end.to raise_exception(Async::Matrix::RequestError)
  end
end
