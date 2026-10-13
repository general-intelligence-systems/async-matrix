# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/to_device"

describe Async::Matrix::ClientServer::ToDevice do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The operation is in every version, so the method is on the class rather than in a layer, and the case needs no version of its own.
  it "can sendToDevice" do
    messages = {self.user_id => {"*" => {algorithm: "m.megolm.v1.aes-sha2", room_id: "!r:localhost"}}}

    expect(client.to_device.send_to_device("m.room_key", messages).value).to be_a(Hash)
  end

  # A to-device message is addressed to one device, so the other device of the same account never sees it.
  it "delivers a message to the device it was addressed to" do
    receiver = self.account(self.username)
    device_id = receiver.get_token_owner.device_id

    client.to_device.send_to_device("m.room_key", {self.user_id => {device_id => {algorithm: "m.megolm.v1.aes-sha2", room_id: "!r:localhost"}}})

    expect(self.to_device_types(receiver)).to be(:include?, "m.room_key")
    expect(self.to_device_types(client)).not.to be(:include?, "m.room_key")
  end

  # The cursor belongs to the device, not the account: a batch acknowledges what the device read, so reading on means the message is gone.
  #
  # This is why a client cannot resume one device's sync from another's token. It would acknowledge messages this device never read, and a key lost that way is lost for good.
  it "delivers a message once, against the cursor of the device it was sent to" do
    receiver = self.account(self.username)
    device_id = receiver.get_token_owner.device_id

    client.to_device.send_to_device("m.room_key", {self.user_id => {device_id => {algorithm: "m.megolm.v1.aes-sha2", room_id: "!r:localhost"}}})

    carried = self.sync_until_to_device(receiver)

    expect(carried).not.to be_nil
    expect(carried.following(timeout: 0).to_device).to be(:empty?)
  end

  # Sync until the device is handed a to-device message, or give up.
  #
  # @parameter authenticated [Client] the device to sync as.
  # @parameter attempts [Integer] how many batches to read.
  # @returns [Sync | nil] the batch which carried one, or nil.
  def sync_until_to_device(authenticated, attempts: 5)
    batches = Enumerator.produce(authenticated.sync(timeout: 0)){|sync| sync.following(timeout: 2000)}

    batches.lazy.take(attempts).find{|sync| !sync.to_device.empty?}
  end

  # @parameter authenticated [Client] the device to sync as.
  # @returns [Array(String)] the type of each to-device message the device was handed.
  def to_device_types(authenticated)
    self.sync_until_to_device(authenticated)&.to_device&.map{|event| event[:type].to_s} || []
  end

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::ToDevice::CASES
end
