# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix"

# Named, because a layer's version comes from its name.
module RemovalsExample
  module V1_2
    extend Async::Matrix::Removals

    removed :get_room_keys_by_session_id, use: :get_room_key_by_session_id

    removed :gone
  end

  class Backup
    include V1_2
  end
end

describe Async::Matrix::Removals do
  let(:backup) {RemovalsExample::Backup.new}

  it "takes its version from the name of the layer" do
    expect(RemovalsExample::V1_2.version).to be == "v1.2"
  end

  it "records what took the place of each operation" do
    expect(RemovalsExample::V1_2.removals).to be == {
      get_room_keys_by_session_id: :get_room_key_by_session_id,
      gone: nil,
    }
  end

  it "raises when a withdrawn operation is called" do
    expect do
      backup.get_room_keys_by_session_id("!room:localhost", "session")
    end.to raise_exception(Async::Matrix::RemovedOperationError)
  end

  it "says which version withdrew it, and what to call instead" do
    error = nil

    begin
      backup.get_room_keys_by_session_id("!room:localhost", "session")
    rescue Async::Matrix::RemovedOperationError => error
    end

    expect(error.name).to be == :get_room_keys_by_session_id
    expect(error.version).to be == "v1.2"
    expect(error.replacement).to be == :get_room_key_by_session_id
    expect(error.message).to be == "#get_room_keys_by_session_id was removed in v1.2: call #get_room_key_by_session_id instead!"
  end

  it "says only that it is gone where nothing took its place" do
    error = nil

    begin
      backup.gone
    rescue Async::Matrix::RemovedOperationError => error
    end

    expect(error.replacement).to be_nil
    expect(error.message).to be == "#gone was removed in v1.2!"
  end

  # A withdrawal has to reach the version which declared it and every version after it, and leave the versions before it alone.
  with "the key backup layers" do
    it "withdraws the plural operations from v1.2 onwards" do
      ["v1.2", "v1.10", "v1.19"].each do |version|
        keys = Async::Matrix::Versions[version]::BackupKeys.new(nil, "1")

        expect do
          keys.get_room_keys_by_session_id("!room:localhost", "session")
        end.to raise_exception(Async::Matrix::RemovedOperationError)
      end
    end

    it "leaves them alone in v1.1, which named them" do
      keys = Async::Matrix::Versions["v1.1"]::BackupKeys

      expect(keys.instance_method(:get_room_keys_by_session_id).owner).to be_equal(Async::Matrix::Abstract::ClientServer::BackupKeys::V1_1)
    end
  end
end
