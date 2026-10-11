# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/application_service_context"
require "async/matrix/operations_context"

describe Async::Matrix::ApplicationService::Ping do
  include Async::Matrix::ApplicationServiceContext
  include Async::Matrix::OperationsContext

  # The homeserver pings a service to check the token it was given, so the answer is empty.
  it "can ping" do
    expect(service.ping.ping(transaction_id: "a-transaction").value).to be == {}
  end

  it "needs no transaction" do
    expect(service.ping.ping.value).to be == {}
  end
end
