# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "console"

require_relative "../../../protocol/matrix/message_batch"

module Async
  module Matrix
    class Client
      # ONE long poll of /sync, decrypted on the way through.
      #
      #   poll = Sync.new(client, store: device_store, since: cursor)
      #
      #   poll.read do |message|
      #     message.decrypted?   # false means we hold no key for it YET
      #     message.type         # the real type, once decrypted
      #     message.content
      #   end
      #
      #   checkpoint(poll.next_batch)
      #
      # A SINGLE REQUEST, NOT A LOOP. Polling forever is {Client#sync}, which
      # builds one of these per round trip and carries the cursor from each to
      # the next; this class exists for a consumer that wants to drive its own
      # loop, or one round trip and nothing more.
      #
      # WHAT A CONSUMER SEES IS MESSAGES. /sync also carries to-device events,
      # device lists and key counts, and none of that is a message: to-device
      # events are how room keys travel, so they are fed to the store and never
      # yielded. A consumer that had to recognise and route them would be
      # reimplementing this class.
      #
      # ORDER IS THE WHOLE TRICK, and MessageBatch provides it. A batch
      # routinely carries both an `m.room_key` and the timeline event that key
      # unlocks; because the batch yields to-device first and the store absorbs
      # keys as it reads them, that event decrypts on its first pass instead of
      # being stored as a placeholder and repaired later.
      #
      # THE STORE IS PASSED IN, holding this device's keys. It is what makes any
      # room readable, and it is optional only in the sense that a consumer
      # interested solely in unencrypted rooms can omit it and receive encrypted
      # messages undecrypted.
      #
      # NOT RESILIENT, DELIBERATELY. A failed request raises. How to react to a
      # homeserver that is down -- retry, back off, give up, alert -- is policy,
      # and policy belongs to whatever is driving the loop rather than to the
      # thing reading the protocol.
      class Sync
        # Synapse holds a /sync request open until something happens or this
        # elapses, so it is a normal quiet-room duration rather than a failure
        # timeout.
        DEFAULT_TIMEOUT = 30_000

        def initialize(client, store: nil, since: nil, timeout: DEFAULT_TIMEOUT, filter: nil)
          @client = client
          @store = store
          @next_batch = since
          @timeout = timeout
          @filter = filter
          @one_time_keys_count = {}
        end

        attr_reader :store, :timeout, :filter

        # The cursor to resume from.
        #
        # COMMIT IT ONLY AFTER THE MESSAGES OF ITS BATCH ARE DURABLE. It advances
        # when a batch is drained, so reading it inside the loop and storing it
        # before handling the message is how a crash loses messages with nothing
        # recording that it happened.
        attr_reader :next_batch

        # What the server last said it still holds of our one-time keys.
        #
        # Surfaced rather than acted on. Running low means topping up, which is
        # an upload, and deciding when to upload is not this object's business --
        # but a device whose keys run out silently stops being reachable, so the
        # number has to be visible to someone.
        attr_reader :one_time_keys_count

        # One round trip. Returns the batch, undecrypted.
        #
        # An INITIAL sync -- no cursor -- asks for the full state of every room
        # the account is in, which is as large as a response gets. A filter is
        # the only thing that makes it smaller.
        def poll
          Protocol::Matrix::MessageBatch.from_sync(fetch)
        end

        # Read one batch, yielding each room message with whatever the store
        # could decrypt.
        #
        # @returns [Integer] how many messages were yielded.
        def read(&block)
          batch = poll
          yielded = 0

          batch.each do |message, _section|
            if batch.to_device?
              handle_to_device(message)
            else
              yielded += 1
              block.call(decrypt(message))
            end
          end

          # AFTER the batch, never during: the cursor says "everything before
          # this has been handed over", and advancing it mid-batch would promise
          # that of messages still in it.
          @next_batch = batch.next_batch
          yielded
        end

        private

          def fetch
            query = {timeout: @timeout}

            if @next_batch
              query[:since] = @next_batch
            end

            if @filter
              query[:filter] = @filter
            end

            response = @client.api.sync.get(**query)
            remember_key_counts(response)
            response
          end

          def remember_key_counts(response)
            counts = response["device_one_time_keys_count"]

            if counts
              @one_time_keys_count = counts
            end
          end

          # To-device messages are plumbing: decrypting one is how a room key
          # reaches the store, and the store absorbs it as it reads. Nothing is
          # yielded.
          #
          # A FAILURE HERE MUST NOT REACH THE LOOP. Anyone sharing a room can
          # send us a to-device message, so a malformed one that propagated
          # would be a remote-controlled crash -- and the loss is recoverable
          # anyway, because a sender who sees us unable to decrypt re-shares the
          # key. Protocol errors are swallowed; anything else is a bug in us and
          # still raises.
          def handle_to_device(message)
            if @store && message.encrypted?
              @store.decrypt(message)
            end
          rescue Protocol::Matrix::Errors::Error => error
            Console.warn(self, "Discarding undecryptable to-device message.", error: error)
            nil
          end

          # An encrypted message with no key is returned AS IT IS, undecrypted.
          # That is not a failure: it is the commonest state in an encrypted
          # room, the key may still arrive, and a consumer that stores the row
          # now can have it repaired in place later.
          def decrypt(message)
            if @store && message.encrypted?
              @store.decrypt(message)
            end

            message
          end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Client::Sync" do
    # A client faked at the api-chain level, so the specs exercise the real call
    # path (client.api.sync.get) rather than a shortcut around it.
    def fake_client(*responses)
      queried = []
      remaining = responses.dup
      client = Object.new
      client.define_singleton_method(:queried) { queried }
      client.define_singleton_method(:api) do
        chain = Object.new
        chain.define_singleton_method(:sync) do
          endpoint = Object.new
          endpoint.define_singleton_method(:get) do |**query|
            queried << query
            remaining.shift || {"next_batch" => "empty"}
          end
          endpoint
        end
        chain
      end
      client
    end

    # A store that records what it was asked to read and "decrypts" whatever it
    # has a key for.
    def fake_store(readable: [])
      store = Object.new
      seen = []
      # Captured as locals: inside define_singleton_method, self is the store,
      # so the spec's own helpers are out of scope.
      olm = olm_session_double
      megolm = megolm_session_double

      store.define_singleton_method(:seen) { seen }
      store.define_singleton_method(:decrypt) do |message|
        seen << message

        if message.olm?
          message.decrypt!(olm, identity_key: message.recipients.first)
          message
        elsif readable.include?(message.session_id)
          message.decrypt!(megolm)
          message
        end
      end
      store
    end

    def megolm_session_double
      session = Object.new
      session.define_singleton_method(:decrypt) do |_ciphertext|
        [JSON.generate({"type" => "m.room.message", "content" => {"body" => "plain"}}), 0]
      end
      session
    end

    # A real olm payload: the OlmPayload schema's required fields are what make
    # the message attributable, and EncryptedMessage refuses one without them.
    def olm_session_double(type: "m.room_key")
      session = Object.new
      session.define_singleton_method(:decrypt) do |_type, _body|
        JSON.generate({
          "type" => type,
          "content" => {"algorithm" => "m.megolm.v1.aes-sha2"},
          "sender" => "@bob:example.org",
          "recipient" => "@us:example.org",
          "recipient_keys" => {"ed25519" => "ours"},
          "keys" => {"ed25519" => "theirs"},
        })
      end
      session
    end

    def encrypted_timeline(session_id: "session1", event_id: "$enc")
      {
        "type" => "m.room.encrypted",
        "event_id" => event_id,
        "sender" => "@alice:example.org",
        "content" => {
          "algorithm" => "m.megolm.v1.aes-sha2",
          "ciphertext" => "AwgAEnAC",
          "session_id" => session_id,
        },
      }
    end

    def plaintext_timeline(event_id = "$msg")
      {
        "type" => "m.room.message",
        "event_id" => event_id,
        "sender" => "@alice:example.org",
        "content" => {"msgtype" => "m.text", "body" => "hello"},
      }
    end

    def to_device_event
      {
        "type" => "m.room.encrypted",
        "sender" => "@bob:example.org",
        "content" => {
          "algorithm" => "m.olm.v1.curve25519-aes-sha2",
          "sender_key" => "theircurve",
          "ciphertext" => {"ourcurve" => {"type" => 0, "body" => "olmbody"}},
        },
      }
    end

    def response(events: [plaintext_timeline], to_device: [], next_batch: "s2", **extra)
      {
        "next_batch" => next_batch,
        "to_device" => {"events" => to_device},
        "rooms" => {"join" => {"!room:example.org" => {"timeline" => {"events" => events}}}},
      }.merge(extra)
    end

    def sync_for(client, **options)
      Async::Matrix::Client::Sync.new(client, **options)
    end

    # ── The request ───────────────────────────────────────────────────────────

    it "polls with a timeout and no cursor on the first request" do
      client = fake_client(response)
      sync_for(client).read { |_message| nil }

      client.queried.should == [{timeout: 30_000}]
    end

    it "sends the cursor it was given" do
      client = fake_client(response)
      sync_for(client, since: "s1").read { |_message| nil }

      client.queried.should == [{timeout: 30_000, since: "s1"}]
    end

    it "sends a filter when it has one" do
      client = fake_client(response)
      sync_for(client, filter: "2", timeout: 100).read { |_message| nil }

      client.queried.should == [{timeout: 100, filter: "2"}]
    end

    it "advances the cursor across polls" do
      client = fake_client(response(next_batch: "s2"), response(next_batch: "s3"))
      sync = sync_for(client)

      sync.next_batch.should.be.nil
      sync.read { |_message| nil }
      sync.next_batch.should == "s2"
      sync.read { |_message| nil }
      sync.next_batch.should == "s3"
      client.queried.last.should == {timeout: 30_000, since: "s2"}
    end

    # ── What is yielded ───────────────────────────────────────────────────────

    it "yields room messages" do
      sync = sync_for(fake_client(response(events: [plaintext_timeline("$a"), plaintext_timeline("$b")])))
      seen = []
      sync.read { |message| seen << message.event_id }

      seen.should == ["$a", "$b"]
    end

    # To-device events are how room keys travel. They are not messages, and a
    # consumer that had to recognise them would be reimplementing this class.
    it "never yields a to-device message" do
      sync = sync_for(
        fake_client(response(to_device: [to_device_event], events: [plaintext_timeline])),
        store: fake_store,
      )
      seen = []
      sync.read { |message| seen << message }

      seen.length.should == 1
      seen.first.type.should == "m.room.message"
    end

    it "still feeds to-device messages to the store" do
      store = fake_store
      sync = sync_for(fake_client(response(to_device: [to_device_event], events: [])), store: store)
      sync.read { |_message| nil }

      store.seen.length.should == 1
      store.seen.first.olm?.should == true
    end

    it "counts what it yielded" do
      sync = sync_for(fake_client(response(events: [plaintext_timeline("$a"), plaintext_timeline("$b")])))

      sync.read { |_message| nil }.should == 2
    end

    it "yields nothing for an empty batch" do
      sync = sync_for(fake_client(response(events: [])))
      seen = []

      sync.read { |message| seen << message }.should == 0
      seen.should == []
    end

    # ── Decryption ────────────────────────────────────────────────────────────

    it "decrypts a room message with the store's keys" do
      sync = sync_for(
        fake_client(response(events: [encrypted_timeline(session_id: "known")])),
        store: fake_store(readable: ["known"]),
      )
      seen = []
      sync.read { |message| seen << message }

      seen.first.decrypted?.should == true
      seen.first.type.should == "m.room.message"
      seen.first.content.should == {"body" => "plain"}
    end

    # NOT A FAILURE, and not a reason to drop the message: the key may still
    # arrive, and a consumer that stored this row can have it repaired later.
    it "yields an encrypted message it has no key for, undecrypted" do
      sync = sync_for(
        fake_client(response(events: [encrypted_timeline(session_id: "unknown")])),
        store: fake_store(readable: []),
      )
      seen = []
      sync.read { |message| seen << message }

      seen.length.should == 1
      seen.first.decrypted?.should == false
      seen.first.encrypted?.should == true
      seen.first.session_id.should == "unknown"
    end

    # A consumer interested only in unencrypted rooms needs no keys at all.
    it "works with no store, leaving encrypted messages alone" do
      sync = sync_for(fake_client(response(events: [encrypted_timeline, plaintext_timeline])))
      seen = []
      sync.read { |message| seen << message }

      seen.length.should == 2
      seen.first.decrypted?.should == false
      seen.last.type.should == "m.room.message"
    end

    it "leaves a plaintext message untouched by the store" do
      store = fake_store
      sync = sync_for(fake_client(response(events: [plaintext_timeline])), store: store)
      sync.read { |_message| nil }

      store.seen.should == []
    end

    # Anyone sharing a room can send us one, so a malformed to-device message
    # must not take the loop down with it.
    it "discards an undecryptable to-device message and keeps going" do
      exploding = Object.new
      exploding.define_singleton_method(:decrypt) do |_message|
        raise(Protocol::Matrix::Errors::MalformedError, "nonsense")
      end

      sync = sync_for(
        fake_client(response(to_device: [to_device_event], events: [plaintext_timeline])),
        store: exploding,
      )
      seen = []

      sync.read { |message| seen << message }.should == 1
      seen.first.type.should == "m.room.message"
    end

    # ── Key counts ────────────────────────────────────────────────────────────

    # A device whose one-time keys run out silently stops being reachable, so
    # the number has to be visible to someone.
    it "remembers what the server says it holds of our one-time keys" do
      sync = sync_for(
        fake_client(response("device_one_time_keys_count" => {"signed_curve25519" => 12})),
      )

      sync.one_time_keys_count.should == {}
      sync.read { |_message| nil }
      sync.one_time_keys_count.should == {"signed_curve25519" => 12}
    end

    it "keeps the last count when a response omits it" do
      client = fake_client(
        response("device_one_time_keys_count" => {"signed_curve25519" => 12}),
        response,
      )
      sync = sync_for(client)
      sync.read { |_message| nil }
      sync.read { |_message| nil }

      sync.one_time_keys_count.should == {"signed_curve25519" => 12}
    end

    # ── The batch, unprocessed ────────────────────────────────────────────────

    it "exposes the raw batch for a caller that wants to drive it itself" do
      batch = sync_for(fake_client(response(to_device: [to_device_event]))).poll

      batch.should.be.kind_of Protocol::Matrix::MessageBatch
      batch.size.should == 2
      batch.next_batch.should == "s2"
    end
  end
