# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/registration"

describe Async::Matrix::ClientServer::Registration do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # Registering needs no account, so these ask as nobody.
  let(:registration) {unauthenticated.registration}

  # These four are in every version, so they are on the class rather than in a layer.
  #
  # The rig sets `enable_registration: false` and registers a user on first login instead, so the homeserver refuses to register one here. The refusal is what the case has to read: the request is the one the specification describes, and it reached the homeserver.
  it "can register" do
    error = nil

    begin
      registration.register(username: "nobody", password: Async::Matrix::TEST_PASSWORD, auth: {type: "m.login.dummy"})
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_FORBIDDEN"
  end

  it "can checkUsernameAvailability" do
    error = nil

    begin
      registration.check_username_availability("nobody")
    rescue Async::Matrix::RequestError => error
    end

    expect(error.errcode).to be == "M_FORBIDDEN"
  end

  # Mail is off in the rig, so the homeserver will not start a validation.
  it "can requestTokenToRegisterEmail" do
    expect do
      registration.request_token_to_register_email("a-secret", "nobody@example.com")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  it "can requestTokenToRegisterMSISDN" do
    expect do
      registration.request_token_to_register_msisdn("a-secret", "GB", "7700900000")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Registration::CASES
end
