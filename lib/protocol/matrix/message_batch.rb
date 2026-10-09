# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "errors"
require_relative "event"
require_relative "encrypted_message"

module Protocol
  module Matrix
    # One batch of messages, read exactly once.
    #
    # A homeserver hands over messages in batches, never one at a time: a /sync
    # response or an application service transaction arrives whole, carrying
    # to-device messages and room timelines together. This is that batch, turned
    # into a single-pass stream — #read gives the next message or nil, in the
    # shape Protocol::GRPC::Body::Readable uses for gRPC frames.
    #
    #   batch = MessageBatch.from_sync(response)
    #
    #   while message = batch.read
    #     message.to_device?   # plumbing (room keys) or timeline?
    #     message.encrypted?   # needs a session before it can be read?
    #   end
    #
    #   batch.next_batch       # the cursor this batch ends at
    #
    # NOT REWINDABLE, AND THAT IS THE POINT. Reading a message is not free:
    # decrypting one ratchets a session forward, so "read it again" is not a
    # thing the protocol can offer. A drained batch answers nil forever, and
    # #each consumes rather than iterating a collection. If a consumer needs to
    # keep a message, it keeps the message — not the batch.
    #
    # TO-DEVICE MESSAGES COME FIRST, always. A batch routinely carries both an
    # `m.room_key` and the timeline event that key unlocks, and the order they
    # are read in decides whether that event decrypts on the first pass or is
    # stored as a placeholder and repaired later. Making the stream ordered is
    # what takes that decision away from the caller and from any scheduler: a
    # timeline message is unreachable until the to-device messages ahead of it
    # have been read.
    #
    # The two wire formats differ, and only in how they are unpacked:
    #
    #   /sync            to_device.events, then rooms.{join,invite,leave}
    #   AS transaction   de.sorunome.msc2409.to_device, then events
    #
    # So they get two constructors and produce one stream, which is why an
    # appservice and a syncing client can share everything downstream of here.
    class MessageBatch
      # Where a message sat in the batch it came from. Carried because a
      # consumer projecting rooms needs to know that an event arrived as invite
      # state rather than timeline, which the event itself does not say.
      SECTIONS = %i[to_device join invite leave transaction].freeze

      Error = Errors::MessageBatchError

      # #read after the batch was drained is fine (nil). This is for a consumer
      # that asks for a second pass over something already consumed.
      ConsumedError = Errors::ConsumedError

      # Unpack a /sync response.
      #
      # @parameter response [Hash] the parsed response body, string keys.
      def self.from_sync(response)
        messages = []

        to_device = response.dig("to_device", "events") || []
        to_device.each { |event| messages << build(event, :to_device, nil) }

        rooms = response["rooms"] || {}

        (rooms["join"] || {}).each do |room_id, data|
          timeline = data.dig("timeline", "events") || []
          timeline.each { |event| messages << build(event, :join, room_id) }
        end

        # Invites carry stripped state and no timeline, but it is the only thing
        # that says who invited us, so dropping it loses the invite itself.
        (rooms["invite"] || {}).each do |room_id, data|
          state = data.dig("invite_state", "events") || []
          state.each { |event| messages << build(event, :invite, room_id) }
        end

        (rooms["leave"] || {}).each do |room_id, data|
          timeline = data.dig("timeline", "events") || []
          timeline.each { |event| messages << build(event, :leave, room_id) }
        end

        new(messages, next_batch: response["next_batch"])
      end

      # Unpack an application service transaction.
      #
      # To-device messages ride the MSC4203 key, which Synapse still sends under
      # its original MSC2409 name; the stable spelling is accepted first so this
      # keeps working when that changes.
      #
      # @parameter transaction [Hash] the parsed PUT body, string keys.
      # @parameter txn_id [String] the transaction id, which is this batch's
      #   cursor — the appservice equivalent of next_batch.
      def self.from_transaction(transaction, txn_id: nil)
        messages = []

        to_device = transaction["to_device"] ||
          transaction["de.sorunome.msc2409.to_device"] || []
        to_device.each { |event| messages << build(event, :to_device, nil) }

        # Transaction events carry their own room_id; there is no per-room
        # grouping to unpack.
        (transaction["events"] || []).each do |event|
          messages << build(event, :transaction, event["room_id"])
        end

        new(messages, next_batch: txn_id)
      end

      # An encrypted event becomes an EncryptedMessage, anything else an Event.
      # Both answer #type, #content, #encrypted?, #decrypted? and #to_device?,
      # so a consumer reads either without asking which it has.
      def self.build(event, section, room_id)
        # A to-device event has no room_id of its own; a /sync room section
        # knows the room its events belong to, and the events themselves may
        # omit it. Supplying it keeps #to_device? honest either way.
        if room_id && event["room_id"].nil?
          event = event.merge("room_id" => room_id)
        end

        if EncryptedMessage.encrypted?(event)
          [EncryptedMessage.new(event), section]
        else
          [Event.new(event), section]
        end
      end

      def initialize(messages, next_batch: nil)
        @messages = messages
        @next_batch = next_batch
        @position = 0
        @section = nil
      end

      # The cursor this batch ends at: `next_batch` from /sync, the transaction
      # id from an appservice.
      #
      # COMMIT IT ONLY ONCE THE BATCH IS DRAINED AND ITS EFFECTS ARE DURABLE.
      # Storing it earlier means a crash loses every message still in this
      # batch, with nothing anywhere recording that they were missed.
      attr_reader :next_batch

      # How many messages the batch held. Fixed at construction — it does not
      # count down as the batch is read.
      def size = @messages.length

      # Have all of them been read?
      def drained? = @position >= @messages.length

      # The next message, or nil once drained. To-device messages first.
      def read
        if drained?
          nil
        else
          message, section = @messages[@position]
          @position += 1
          @section = section
          message
        end
      end

      # The section the message most recently returned by #read came from, one
      # of SECTIONS. Read it after #read, not before.
      attr_reader :section

      # Did the last message read arrive as to-device rather than from a room?
      #
      # ON THE BATCH, NOT THE MESSAGE, because the batch is the only thing that
      # knows. Asking the message would mean inferring it from a missing
      # room_id, and that is wrong twice over: a transaction timeline event may
      # omit the room_id the section supplies, and inference would call it
      # to-device. The section is stated by the wire format; nothing has to
      # guess.
      def to_device? = @section == :to_device

      # Read every remaining message. CONSUMES the batch: this is a drain, not
      # an iteration, and a second call yields nothing because there is nothing
      # left rather than because iteration restarted.
      def each
        unless block_given?
          raise ConsumedError, "MessageBatch#each requires a block; a batch is not enumerable"
        end

        while (message = read)
          yield(message, @section)
        end

        self
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::MessageBatch" do
    def to_device_event
      {
        "type" => "m.room.encrypted",
        "sender" => "@bob:example.org",
        "content" => {
          "algorithm" => "m.olm.v1.curve25519-aes-sha2",
          "sender_key" => "senderkey",
          "ciphertext" => {"ourkey" => {"type" => 0, "body" => "body"}},
        },
      }
    end

    def encrypted_timeline_event(event_id = "$enc1")
      {
        "type" => "m.room.encrypted",
        "event_id" => event_id,
        "sender" => "@alice:example.org",
        "origin_server_ts" => 1,
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "ciphertext" => "AwgAEnAC",
          "session_id" => "session1",
        },
      }
    end

    def plaintext_event(event_id = "$msg1")
      {
        "type" => "m.room.message",
        "event_id" => event_id,
        "sender" => "@alice:example.org",
        "origin_server_ts" => 2,
        "content" => {"msgtype" => "m.text", "body" => "hello"},
      }
    end

    def sync_response(extra = {})
      {
        "next_batch" => "s72_1234",
        "to_device" => {"events" => [to_device_event]},
        "rooms" => {
          "join" => {
            "!room:example.org" => {
              "timeline" => {"events" => [encrypted_timeline_event, plaintext_event]},
            },
          },
        },
      }.merge(extra)
    end

    # ── Unpacking /sync ───────────────────────────────────────────────────────

    it "reads every message in the batch, then nil" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)

      batch.size.should == 3
      batch.read.should.be.kind_of Protocol::Matrix::EncryptedMessage
      batch.read.should.be.kind_of Protocol::Matrix::EncryptedMessage
      batch.read.should.be.kind_of Protocol::Matrix::Event
      batch.read.should.be.nil
      batch.drained?.should == true
    end

    # THE ORDERING GUARANTEE. A batch carrying both a room key and the event it
    # unlocks must hand over the key first, or the event decrypts as a
    # placeholder on the first pass.
    it "yields to-device messages before any timeline message" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)

      batch.read
      batch.to_device?.should == true
      batch.section.should == :to_device

      batch.read
      batch.to_device?.should == false
      batch.section.should == :join
    end

    it "carries the cursor the batch ends at" do
      Protocol::Matrix::MessageBatch.from_sync(sync_response).next_batch.should == "s72_1234"
    end

    it "builds an EncryptedMessage for an encrypted event and an Event otherwise" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      batch.read

      encrypted = batch.read
      encrypted.encrypted?.should == true
      encrypted.decrypted?.should == false
      encrypted.session_id.should == "session1"

      plain = batch.read
      plain.encrypted?.should == false
      plain.decrypted?.should == true
      plain.type.should == "m.room.message"
      plain.content.body.should == "hello"
    end

    # A /sync room section knows the room; the events inside it may not repeat it.
    it "attributes a timeline event to its room" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      batch.read

      batch.read.room_id.should == "!room:example.org"
    end

    it "leaves a to-device message without a room" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)

      batch.read.room_id.should.be.nil
      batch.to_device?.should == true
    end

    it "does not overwrite a room_id the event already carries" do
      event = encrypted_timeline_event.merge("room_id" => "!actual:example.org")
      response = {
        "rooms" => {"join" => {"!section:example.org" => {"timeline" => {"events" => [event]}}}},
      }

      Protocol::Matrix::MessageBatch.from_sync(response).read.room_id.should == "!actual:example.org"
    end

    it "reads invite state, which is the only record of the invite" do
      response = {
        "rooms" => {
          "invite" => {
            "!invited:example.org" => {
              "invite_state" => {
                "events" => [{
                  "type" => "m.room.member",
                  "sender" => "@carol:example.org",
                  "state_key" => "@us:example.org",
                  "content" => {"membership" => "invite"},
                }],
              },
            },
          },
        },
      }
      batch = Protocol::Matrix::MessageBatch.from_sync(response)
      message = batch.read

      message.type.should == "m.room.member"
      message.room_id.should == "!invited:example.org"
      batch.section.should == :invite
    end

    it "reads the timeline of a room we left" do
      response = {
        "rooms" => {
          "leave" => {"!gone:example.org" => {"timeline" => {"events" => [plaintext_event]}}},
        },
      }
      batch = Protocol::Matrix::MessageBatch.from_sync(response)
      batch.read

      batch.section.should == :leave
    end

    it "handles an empty sync with nothing in it" do
      batch = Protocol::Matrix::MessageBatch.from_sync({"next_batch" => "s1"})

      batch.size.should == 0
      batch.drained?.should == true
      batch.read.should.be.nil
      batch.next_batch.should == "s1"
    end

    # ── Unpacking an appservice transaction ───────────────────────────────────

    it "unpacks a transaction into the same stream" do
      transaction = {
        "de.sorunome.msc2409.to_device" => [to_device_event],
        "events" => [encrypted_timeline_event.merge("room_id" => "!room:example.org")],
      }
      batch = Protocol::Matrix::MessageBatch.from_transaction(transaction, txn_id: "txn42")

      batch.size.should == 2
      batch.read
      batch.to_device?.should == true
      batch.section.should == :to_device

      timeline = batch.read
      timeline.room_id.should == "!room:example.org"
      batch.section.should == :transaction
      batch.next_batch.should == "txn42"
    end

    # Synapse sends the unstable MSC2409 spelling today; the stable MSC4203 key
    # is preferred so this keeps working when that lands.
    it "prefers the stable to_device key over the unstable one" do
      transaction = {
        "to_device" => [to_device_event],
        "de.sorunome.msc2409.to_device" => [to_device_event, to_device_event],
      }

      Protocol::Matrix::MessageBatch.from_transaction(transaction).size.should == 1
    end

    it "handles a transaction with no to-device messages" do
      transaction = {"events" => [plaintext_event]}
      batch = Protocol::Matrix::MessageBatch.from_transaction(transaction)

      batch.size.should == 1
      batch.read.type.should == "m.room.message"
      batch.to_device?.should == false
      batch.section.should == :transaction
    end

    it "handles an empty transaction" do
      batch = Protocol::Matrix::MessageBatch.from_transaction({})

      batch.size.should == 0
      batch.read.should.be.nil
    end

    # ── Read exactly once ─────────────────────────────────────────────────────

    # Decrypting ratchets a session forward, so "read it again" is not something
    # the protocol can offer. A drained batch stays drained.
    it "cannot be rewound" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      3.times { batch.read }

      batch.read.should.be.nil
      batch.read.should.be.nil
      batch.drained?.should == true
    end

    it "consumes the batch when drained with each" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      seen = []
      batch.each { |message| seen << message }

      seen.length.should == 3
      batch.drained?.should == true

      again = []
      batch.each { |message| again << message }
      again.should == []
    end

    it "reports the section alongside each message in each" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      sections = []
      batch.each { |_message, section| sections << section }

      sections.should == [:to_device, :join, :join]
    end

    it "continues a partly read batch rather than restarting" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      batch.read

      remaining = []
      batch.each { |message| remaining << message }

      remaining.length.should == 2
    end

    # A batch is a stream, not a collection: there is no non-consuming read, so
    # #each without a block has nothing sensible to return.
    it "refuses to be treated as an enumerable" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)

      lambda { batch.each }.should.raise(Protocol::Matrix::MessageBatch::ConsumedError)
    end

    it "keeps size fixed as it is read" do
      batch = Protocol::Matrix::MessageBatch.from_sync(sync_response)
      batch.read

      batch.size.should == 3
    end

    it "has no section before anything has been read" do
      Protocol::Matrix::MessageBatch.from_sync(sync_response).section.should.be.nil
    end
  end
