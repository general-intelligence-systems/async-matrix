# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

describe Async::Matrix::Identity::V2InvitationSigning do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # The token is one a stored invitation carried, and the rig can store none, so the server has no record of this one.
  it "can blindlySignStuffV2" do
    error = nil

    begin
      identity.v2_invitation_signing.blindly_sign_stuff_v2(self.user_id, "a-token", "a-private-key")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_UNRECOGNIZED"
  end
end
