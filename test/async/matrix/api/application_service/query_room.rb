# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/application_service/query_room"

describe Async::Matrix::ApplicationService::QueryRoom do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  it "can queryRoomByAlias" do
    expect(service.query_room.query_room_by_alias(Async::Matrix::APPLICATION_SERVICE_ALIAS).value).to be == {}
  end

  it "has no alias it does not own" do
    expect do
      service.query_room.query_room_by_alias("#nowhere:localhost")
    end.to raise_exception(Async::Matrix::RequestError)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ApplicationService::QueryRoom::CASES
end
