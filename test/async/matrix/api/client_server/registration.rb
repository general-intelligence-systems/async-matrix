# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

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
  # Whether the homeserver will register an account is the rig's to decide, and the two rigs decide it differently: the `synapse/` one sets `enable_registration: false` and registers a user on first login instead, where the `tuwunel/` one has to leave registration open, because tuwunel cannot be made to accept any password. So the case reads the answer the rig under test gives. Either answer says the same thing about the operation: the request is the one the specification describes, and it reached the homeserver.
  let(:nobody) {"nobody-#{SecureRandom.hex(6)}"}

  it "can register" do
    if Async::Matrix::TEST_ACCOUNTS == "register"
      login = registration.register(username: nobody, password: Async::Matrix::TEST_PASSWORD, auth: {type: "m.login.dummy"})

      expect(login.user_id).to be == "@#{nobody}:localhost"
    else
      error = nil

      begin
        registration.register(username: nobody, password: Async::Matrix::TEST_PASSWORD, auth: {type: "m.login.dummy"})
      rescue Async::Matrix::RequestError => error
      end

      expect(error.errcode).to be == "M_FORBIDDEN"
    end
  end

  it "can checkUsernameAvailability" do
    if Async::Matrix::TEST_ACCOUNTS == "register"
      expect(registration.check_username_availability(nobody)).to be(:available?)
    else
      error = nil

      begin
        registration.check_username_availability(nobody)
      rescue Async::Matrix::RequestError => error
      end

      expect(error.errcode).to be == "M_FORBIDDEN"
    end
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
