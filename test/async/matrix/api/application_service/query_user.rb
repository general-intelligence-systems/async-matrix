# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/application_service/query_user"

describe Async::Matrix::ApplicationService::QueryUser do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  it "can queryUserById" do
    expect(service.query_user.query_user_by_id(Async::Matrix::APPLICATION_SERVICE_USER).value).to be == {}
  end

  # A service says what it does not own by answering that it has nobody.
  it "has nobody it does not own" do
    expect do
      service.query_user.query_user_by_id("@nobody:localhost")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ApplicationService::QueryUser::CASES
end
