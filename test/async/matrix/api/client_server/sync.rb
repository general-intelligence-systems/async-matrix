# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/sync"

# Counts the sync requests which reached the homeserver, and forwards each one.
class CountingDelegate < Protocol::HTTP::Middleware
  def initialize(delegate)
    super(delegate)

    @syncs = 0
  end

  # @attribute [Integer] how many sync requests arrived.
  attr :syncs

  def call(request)
    if request.path.include?("/sync")
      @syncs += 1
    end

    super
  end
end

describe Async::Matrix::ClientServer::Sync do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::ClientServer::Sync::CASES

  with "an initial sync" do
    it "reports a batch token" do
      sync = client.sync(timeout: 0)

      expect(sync.next_batch).to be_a(String)
    end

    it "includes rooms the user has joined" do
      room

      sync = client.sync(timeout: 0)

      expect(sync.joined).to be(:key?, room.id.to_sym)
    end

    it "enumerates timeline events with their room id" do
      body = "synced"

      room.send_message("m.room.message", {msgtype: "m.text", body: body})

      sync = sync_until_message(body)

      expect(sync).not.to be_nil

      # Room IDs are symbols in the parsed payload, and the envelope is given the string form:
      events = sync.each_event.select{|event| event.room_id == room.id}

      expect(events).not.to be(:empty?)
      expect(events.first.room_id).to be_a(String)
    end

    it "enumerates messages" do
      body = "a message"

      room.send_message("m.room.message", {msgtype: "m.text", body: body})

      sync = sync_until_message(body)

      expect(sync).not.to be_nil

      messages = sync.each_message.select{|message| message.room_id == room.id}

      expect(messages.map{|message| message.content.body}).to be(:include?, body)

      # The content is typed by the registry for this client's version, not by the unversioned classes:
      expect(messages.first.content.version).to be == Async::Matrix::TEST_VERSION
    end
  end

  with "#each" do
    let(:counter) {CountingDelegate.new(unauthenticated.delegate)}

    # A session which cannot renew, so the logout below is what the loop meets rather than a renewal.
    let(:counted) {self.account(username, through: Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].new(counter, unauthenticated.reference), refreshable: false)}

    # Logging out invalidates the token, so the homeserver itself fails the next long poll.
    def interrupted
      counted.sync(timeout: 0).tap do
        counted.logout
      end
    end

    # The default is what the loop has always done, so nothing changes for a caller which asks for nothing.
    it "ends the loop on a failure it was not told to retry" do
      sync = interrupted
      requests = counter.syncs
      batches = 0
      error = nil

      begin
        sync.each(timeout: 0){batches += 1}
      rescue Async::Matrix::RequestError => error
      end

      expect(batches).to be == 1
      expect(counter.syncs - requests).to be == 1
      expect(error.status).to be == 401
    end

    it "asks again as many times as it was told to, and then gives up" do
      sync = interrupted
      requests = counter.syncs
      error = nil

      begin
        sync.each(retries: 2, backoff: 0, timeout: 0){nil}
      rescue Async::Matrix::RequestError => error
      end

      # The batch which failed is asked for once, and then twice more:
      expect(counter.syncs - requests).to be == 3
      expect(error.status).to be == 401
    end
  end

  with "#following" do
    it "is woken by an event sent while the request is in flight" do
      body = "woke the long poll"

      # Create the room first: otherwise the long poll is woken by the room creation itself, and returns a batch which does not contain the message yet.
      room

      # Establish a current cursor, so the long poll is woken rather than returning immediately:
      sync = current_sync

      writer = Async do
        sleep 0.2
        room.send_message("m.room.message", {msgtype: "m.text", body: body})
      end

      following = sync.following(timeout: 10_000)

      expect(following.each_message.map{|message| message.content.body}).to be(:include?, body)
    ensure
      writer&.wait
    end

    it "continues from the previous batch" do
      room

      sync = current_sync

      room.send_message("m.room.message", {msgtype: "m.text", body: "next batch"})

      following = sync.following(timeout: 5000)

      expect(following.next_batch).not.to be == sync.next_batch
    end
  end
end
