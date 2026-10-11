# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/identity_context"
require "async/matrix/operations_context"

describe Async::Matrix::Identity::V2Associations do
  include Async::Matrix::IdentityContext
  include Async::Matrix::OperationsContext

  # An address is bound once a validation session has validated it, and the rig can send nothing for a user to validate with: these assert the refusals which say so.
  it "can getValidated3pidV2" do
    error = nil

    begin
      identity.v2_associations.get_validated_3pid_v2("a-session", "a-secret")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_NO_VALID_SESSION"
  end

  it "can bindV2" do
    error = nil

    begin
      identity.v2_associations.bind_v2("a-session", "a-secret", self.user_id)
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_NO_VALID_SESSION"
  end

  # Unbinding is the homeserver's to ask for, signed as itself, which a client cannot be: the server asks for a signature rather than a token.
  it "can unbindV2" do
    error = nil

    begin
      identity.v2_associations.unbind_v2(self.user_id, {medium: "email", address: "nobody@example.com"})
    rescue Async::Matrix::RequestError => error
    end

    expect(error.status).to be == 401
  end
end
