# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/notifications"

describe Async::Matrix::ClientServer::Notifications do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer.
  it "can getNotifications" do
    notified = client.notifications.get_notifications(limit: 5)

    expect(notified.notifications).to be_a(Array)
    expect(notified).to be(:empty?)
  end

  it "takes only the highlights where it is asked to" do
    expect(client.notifications.get_notifications(only: "highlight").notifications).to be_a(Array)
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Notifications::CASES
end
