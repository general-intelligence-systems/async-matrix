# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/push_gateway_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/push_gateway/push_notifier"

describe Async::Matrix::PushGateway::PushNotifier do
  include Async::Matrix::PushGatewayContext
  include Async::Matrix::OperationsContext

  # A gateway is told about an application by whoever wrote it. This one knows nothing of the application the device names, so the key is one it rejects: that is the answer the specification describes for a key which cannot be pushed to.
  it "can notify" do
    notified = unauthenticated.push_notifier.notify(notification)

    expect(notified.rejected).to be(:include?, "a-push-key")
    expect(notified).not.to be(:accepted?)
  end

  # Every key is answered for, so two devices are two answers.
  it "answers for every device it was given" do
    both = notification.merge(devices: [device, device.merge(pushkey: "another-push-key")])

    expect(unauthenticated.push_notifier.notify(both).rejected.size).to be == 2
  end

  # A notification is for the devices it names, so one which names none is not a notification: the gateway refuses it rather than answering that it rejected nothing.
  it "refuses a notification with nobody to push to" do
    error = nil

    begin
      unauthenticated.push_notifier.notify(notification.merge(devices: []))
    rescue Async::Matrix::RequestError => error
    end

    expect(error.status).to be == 400
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::PushGateway::PushNotifier::CASES
end
