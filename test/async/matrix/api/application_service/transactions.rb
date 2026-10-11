# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

describe Async::Matrix::ApplicationService::Transactions do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  it "can sendTransaction" do
    expect(service.transactions.send_transaction("1", [{type: "m.room.message", content: {body: "hello"}}]).value).to be == {}
  end

  # The transaction ID makes it idempotent, so handing the same one over twice is the same answer.
  it "takes the same transaction twice" do
    service.transactions.send_transaction("2", [])

    expect(service.transactions.send_transaction("2", []).value).to be == {}
  end
end
