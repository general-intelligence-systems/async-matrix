# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

describe Async::Matrix::ClientServer::Pusher do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:pushkey) {"key-#{SecureRandom.hex(6)}"}

  # The operations are in every version, so the methods are on the class rather than in a layer.
  it "can postPusher" do
    expect(client.pusher.post_pusher(pushkey, "http", "com.example.app",
      app_display_name: "An Application",
      device_display_name: "A Device",
      lang: "en",
      data: {url: "https://example.com/_matrix/push/v1/notify"},
    ).value).to be == {}
  end

  it "can getPushers" do
    client.pusher.post_pusher(pushkey, "http", "com.example.app",
      app_display_name: "An Application",
      device_display_name: "A Device",
      lang: "en",
      data: {url: "https://example.com/_matrix/push/v1/notify"},
    )

    expect(client.pusher.get_pushers.pushkeys).to be(:include?, pushkey)
  end

  it "has no pushers on an account which set none" do
    expect(client.pusher.get_pushers).to be(:empty?)
  end
end
