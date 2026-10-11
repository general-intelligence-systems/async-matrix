# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/identity/v2_store_invite"

describe Async::Matrix::Identity::V2StoreInvite do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # Holding an invitation means being able to tell whoever claims the address, and the rig has no mail to tell them with.
  it "can storeInviteV2" do
    expect do
      identity.v2_store_invite.store_invite_v2("email", "nobody@example.com", "!a-room:localhost", self.user_id, room_name: "A Room")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Identity::V2StoreInvite::CASES
end
