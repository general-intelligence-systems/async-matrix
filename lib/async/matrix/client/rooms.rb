# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "securerandom"

module Async
  module Matrix
    class Client
      # Room actions: membership, state, events, moderation. Mixed into Client.
      #
      # Every method takes keyword arguments and routes through #api, so the
      # path is checked against the vendored OpenAPI tree before any request is
      # made. Room ids are full of punctuation -- `!id:server`, `@user:server`,
      # `$event` -- and the chain URL-encodes each segment, which is the thing
      # hand-built paths get wrong.
      #
      # NOTHING HERE ENCRYPTS. #send_event sends exactly the content it is
      # given; deciding whether a room is encrypted, and encrypting if so, is
      # the device's job, because only the device holds the keys.
      module Rooms
        # ── Membership ────────────────────────────────────────────────────────

        def invite(room_id:, user_id:, reason: nil)
          api.rooms(room_id).invite.post({user_id: user_id, reason: reason}.compact)
        end

        def kick(room_id:, user_id:, reason: nil)
          api.rooms(room_id).kick.post({user_id: user_id, reason: reason}.compact)
        end

        def ban(room_id:, user_id:, reason: nil)
          api.rooms(room_id).ban.post({user_id: user_id, reason: reason}.compact)
        end

        def unban(room_id:, user_id:, reason: nil)
          api.rooms(room_id).unban.post({user_id: user_id, reason: reason}.compact)
        end

        # Drop a left room from our room list entirely.
        def forget_room(room_id:)
          api.rooms(room_id).forget.post({})
        end

        # The room's CURRENT joined members, straight from the homeserver.
        #
        # AUTHORITATIVE IN A WAY A LOCAL PROJECTION IS NOT. A projection is built
        # from the m.room.member events we happened to receive, so a device that
        # joined an existing room knows only whoever its own join batch
        # mentioned. Encrypting to that list means encrypting to a subset of the
        # room, and the rest see an undecryptable message.
        def joined_members(room_id:)
          api.rooms(room_id).joined_members.get
        end

        def joined_rooms = api.joined_rooms.get

        def create_room(**options)
          api.createRoom.post(options)
        end

        # ── Events ────────────────────────────────────────────────────────────

        # PUT /rooms/{roomId}/send/{eventType}/{txnId}
        #
        # The transaction id is what makes a retry safe: the homeserver
        # deduplicates on it, so a request that timed out after being processed
        # does not post the message twice.
        def send_event(room_id:, event_type:, content:, txn_id: nil)
          api.rooms(room_id).send(event_type, txn_id || SecureRandom.uuid).put(content)
        end

        # Deleting an event, in Matrix's own vocabulary.
        def redact(room_id:, event_id:, reason: nil, txn_id: nil)
          api.rooms(room_id).redact(event_id, txn_id || SecureRandom.uuid)
            .put({reason: reason}.compact)
        end

        # Backwards pagination, for "load older messages". `dir: "b"` is
        # backwards from the token given.
        def messages(room_id:, from: nil, to: nil, dir: "b", limit: 50, filter: nil)
          query = {dir: dir, limit: limit}

          if from
            query[:from] = from
          end

          if to
            query[:to] = to
          end

          if filter
            query[:filter] = filter
          end

          api.rooms(room_id).messages.get(**query)
        end

        def event(room_id:, event_id:)
          api.rooms(room_id).event(event_id).get
        end

        # ── State ─────────────────────────────────────────────────────────────

        # The empty state key is the common case and still a real path segment,
        # which is why it is sent rather than omitted.
        def send_state(room_id:, event_type:, content:, state_key: "")
          api.rooms(room_id).state(event_type, state_key).put(content)
        end

        def get_state(room_id:, event_type:, state_key: "")
          api.rooms(room_id).state(event_type, state_key).get
        end

        def room_state(room_id:)
          api.rooms(room_id).state.get
        end

        def set_room_name(room_id:, name:)
          send_state(room_id: room_id, event_type: "m.room.name", content: {name: name})
        end

        def set_room_topic(room_id:, topic:)
          send_state(room_id: room_id, event_type: "m.room.topic", content: {topic: topic})
        end

        def set_pinned_events(room_id:, event_ids:)
          send_state(
            room_id:    room_id,
            event_type: "m.room.pinned_events",
            content:    {pinned: event_ids},
          )
        end

        # Read-modify-write, because the whole power_levels content is replaced
        # by a state send: writing only the one user would strip every other
        # level in the room.
        def set_power_level(room_id:, user_id:, level:)
          levels = get_state(room_id: room_id, event_type: "m.room.power_levels")
          users = (levels["users"] || {}).merge(user_id => level)

          send_state(
            room_id:    room_id,
            event_type: "m.room.power_levels",
            content:    levels.merge("users" => users),
          )
        end

        # ── Ephemeral ─────────────────────────────────────────────────────────

        def read_receipt(room_id:, event_id:, receipt_type: "m.read")
          api.rooms(room_id).receipt(receipt_type, event_id).post({})
        end

        def typing(room_id:, user_id:, typing:, timeout: 30_000)
          body = {typing: typing}

          if typing
            body[:timeout] = timeout
          end

          api.rooms(room_id).typing(user_id).put(body)
        end

        # ── Account data ──────────────────────────────────────────────────────
        #
        # Where 4S secrets and the m.direct map live, among other things.

        def account_data(user_id:, type:)
          api.user(user_id).account_data(type).get
        end

        def set_account_data(user_id:, type:, content:)
          api.user(user_id).account_data(type).put(content)
        end

        def room_account_data(user_id:, room_id:, type:)
          api.user(user_id).rooms(room_id).account_data(type).get
        end

        def set_room_account_data(user_id:, room_id:, type:, content:)
          api.user(user_id).rooms(room_id).account_data(type).put(content)
        end

        # ── Profile ───────────────────────────────────────────────────────────

        def profile(user_id:) = api.profile(user_id).get

        def set_avatar_url(user_id:, avatar_url:)
          api.profile(user_id).avatar_url.put({avatar_url: avatar_url})
        end
      end
    end
  end
end

__END__
  describe "Async::Matrix::Client::Rooms" do
    def recording_client(response = {})
      # The REAL path tree. Api memoises it process-wide, and the Api specs
      # inject a small fixture tree without restoring it (Api.reset! exists for
      # that and goes uncalled), so without this these specs pass or fail
      # according to the order scampi happens to load files in.
      Async::Matrix::Api.reset!

      config = Async::Matrix::Config.new({
        "homeserver" => {"address" => "http://synapse:8008", "domain" => "example.org"},
        "appservice" => {"as_token" => "as", "hs_token" => "hs", "bot" => {"username" => "bot"}},
      })
      client = Async::Matrix::Client.new(config)
      calls = []
      client.define_singleton_method(:calls) { calls }
      client.define_singleton_method(:request) do |method, path, body = nil, **_options|
        calls << [method, path, body]
        response
      end
      client
    end

    def last(client) = client.calls.last
    def room = "!ops:example.org"

    # ── Encoding ──────────────────────────────────────────────────────────────

    # Room ids are `!id:server`, users `@user:server`, events `$base64`. Getting
    # this wrong is what hand-built paths do.
    it "url-encodes the punctuation in matrix identifiers" do
      client = recording_client
      client.invite(room_id: room, user_id: "@ada:example.org")

      last(client)[1].should == "/_matrix/client/v3/rooms/%21ops%3Aexample.org/invite"
    end

    it "encodes an event id's reserved characters" do
      client = recording_client
      client.event(room_id: room, event_id: "$abc+def/ghi")

      last(client)[1].should.be.include? "%24abc%2Bdef%2Fghi"
    end

    # ── Membership ────────────────────────────────────────────────────────────

    it "invites, kicks, bans and unbans" do
      client = recording_client

      client.invite(room_id: room, user_id: "@ada:example.org")
      last(client)[1].should.be.end_with? "/invite"
      last(client)[2].should == {user_id: "@ada:example.org"}

      client.kick(room_id: room, user_id: "@ada:example.org", reason: "spam")
      last(client)[1].should.be.end_with? "/kick"
      last(client)[2].should == {user_id: "@ada:example.org", reason: "spam"}

      client.ban(room_id: room, user_id: "@ada:example.org")
      last(client)[1].should.be.end_with? "/ban"

      client.unban(room_id: room, user_id: "@ada:example.org")
      last(client)[1].should.be.end_with? "/unban"
    end

    it "omits a reason it was not given" do
      client = recording_client
      client.kick(room_id: room, user_id: "@ada:example.org")

      last(client)[2].key?(:reason).should == false
    end

    # Both forms, so the action surface is consistent without breaking callers
    # written against the positional signature.
    it "joins and leaves by keyword or positionally" do
      client = recording_client

      client.join_room(room_id: room)
      last(client)[1].should == "/_matrix/client/v3/join/%21ops%3Aexample.org"

      client.join_room(room)
      last(client)[1].should == "/_matrix/client/v3/join/%21ops%3Aexample.org"

      client.leave_room(room_id: room)
      last(client)[1].should.be.end_with? "/leave"

      client.leave_room(room)
      last(client)[1].should.be.end_with? "/leave"
    end

    it "forgets a room" do
      client = recording_client
      client.forget_room(room_id: room)

      last(client)[1].should.be.end_with? "/forget"
    end

    # Authoritative in a way a local projection is not: a device that joined an
    # existing room knows only whoever its own join batch mentioned.
    it "reads the room's joined members from the homeserver" do
      client = recording_client
      client.joined_members(room_id: room)

      last(client)[0].should == "GET"
      last(client)[1].should.be.end_with? "/joined_members"
    end

    it "creates a room" do
      client = recording_client
      client.create_room(name: "ops", preset: "private_chat", invite: ["@ada:example.org"])

      last(client)[1].should == "/_matrix/client/v3/createRoom"
      last(client)[2].should == {name: "ops", preset: "private_chat", invite: ["@ada:example.org"]}
    end

    # ── Events ────────────────────────────────────────────────────────────────

    # The transaction id is what makes a retry safe.
    it "sends an event with a transaction id" do
      client = recording_client
      client.send_event(
        room_id: room, event_type: "m.room.message", content: {msgtype: "m.text", body: "hi"},
      )

      last(client)[0].should == "PUT"
      last(client)[1].should.be.include? "/send/m.room.message/"
      last(client)[2].should == {msgtype: "m.text", body: "hi"}
    end

    it "accepts a caller's transaction id" do
      client = recording_client
      client.send_event(room_id: room, event_type: "m.room.message", content: {}, txn_id: "t1")

      last(client)[1].should.be.end_with? "/send/m.room.message/t1"
    end

    # NOTHING HERE ENCRYPTS: the content is sent exactly as given, because only
    # the device holds the keys.
    it "sends encrypted content as-is when handed it" do
      client = recording_client
      client.send_event(
        room_id: room,
        event_type: "m.room.encrypted",
        content: {"algorithm" => "m.megolm.v1.aes-sha2", "ciphertext" => "AwgAEnAC"},
      )

      last(client)[2]["ciphertext"].should == "AwgAEnAC"
    end

    it "redacts an event" do
      client = recording_client
      client.redact(room_id: room, event_id: "$evt", reason: "mistake", txn_id: "t1")

      last(client)[1].should.be.end_with? "/redact/%24evt/t1"
      last(client)[2].should == {reason: "mistake"}
    end

    it "paginates backwards by default" do
      client = recording_client
      client.messages(room_id: room, from: "t42", limit: 20)

      last(client)[0].should == "GET"
      last(client)[1].should ==
        "/_matrix/client/v3/rooms/%21ops%3Aexample.org/messages?dir=b&limit=20&from=t42"
    end

    it "omits pagination parameters it was not given" do
      client = recording_client
      client.messages(room_id: room)

      last(client)[1].should.not.be.include? "from="
      last(client)[1].should.not.be.include? "to="
    end

    # ── State ─────────────────────────────────────────────────────────────────

    # The empty state key is the common case and still a real path segment.
    it "sends and reads state with an empty state key" do
      client = recording_client

      client.send_state(room_id: room, event_type: "m.room.name", content: {name: "ops"})
      last(client)[1].should.be.end_with? "/state/m.room.name/"

      client.get_state(room_id: room, event_type: "m.room.name")
      last(client)[0].should == "GET"
    end

    it "sends state with a state key" do
      client = recording_client
      client.send_state(
        room_id: room, event_type: "m.room.member",
        content: {membership: "join"}, state_key: "@ada:example.org",
      )

      last(client)[1].should.be.end_with? "/state/m.room.member/%40ada%3Aexample.org"
    end

    it "sets the name, topic and pinned events" do
      client = recording_client

      client.set_room_name(room_id: room, name: "ops")
      last(client)[2].should == {name: "ops"}

      client.set_room_topic(room_id: room, topic: "operations")
      last(client)[2].should == {topic: "operations"}

      client.set_pinned_events(room_id: room, event_ids: ["$a", "$b"])
      last(client)[2].should == {pinned: ["$a", "$b"]}
    end

    # Read-modify-write: a state send REPLACES the content, so writing only the
    # one user would strip every other level in the room.
    it "preserves the other power levels when setting one" do
      client = recording_client(
        {"users" => {"@bot:example.org" => 100}, "users_default" => 0, "kick" => 50},
      )
      client.set_power_level(room_id: room, user_id: "@ada:example.org", level: 50)

      last(client)[2].should == {
        "users" => {"@bot:example.org" => 100, "@ada:example.org" => 50},
        "users_default" => 0,
        "kick" => 50,
      }
    end

    # ── Ephemeral ─────────────────────────────────────────────────────────────

    it "posts a read receipt" do
      client = recording_client
      client.read_receipt(room_id: room, event_id: "$evt")

      last(client)[0].should == "POST"
      last(client)[1].should.be.end_with? "/receipt/m.read/%24evt"
    end

    it "sets typing with a timeout, and clears it without one" do
      client = recording_client

      client.typing(room_id: room, user_id: "@bot:example.org", typing: true)
      last(client)[2].should == {typing: true, timeout: 30_000}

      client.typing(room_id: room, user_id: "@bot:example.org", typing: false)
      last(client)[2].should == {typing: false}
    end

    # ── Account data ──────────────────────────────────────────────────────────

    # Where 4S secrets and the m.direct map live.
    it "reads and writes account data" do
      client = recording_client

      client.account_data(user_id: "@bot:example.org", type: "m.secret_storage.default_key")
      last(client)[0].should == "GET"
      last(client)[1].should ==
        "/_matrix/client/v3/user/%40bot%3Aexample.org/account_data/m.secret_storage.default_key"

      client.set_account_data(
        user_id: "@bot:example.org", type: "m.direct", content: {"@ada:example.org" => [room]},
      )
      last(client)[0].should == "PUT"
      last(client)[2].should == {"@ada:example.org" => [room]}
    end

    it "reads and writes per-room account data" do
      client = recording_client
      client.room_account_data(user_id: "@bot:example.org", room_id: room, type: "m.tag")

      last(client)[1].should.be.include? "/rooms/%21ops%3Aexample.org/account_data/m.tag"
    end

    # ── Profile ───────────────────────────────────────────────────────────────

    it "reads a profile and sets an avatar" do
      client = recording_client

      client.profile(user_id: "@ada:example.org")
      last(client)[1].should == "/_matrix/client/v3/profile/%40ada%3Aexample.org"

      client.set_avatar_url(user_id: "@bot:example.org", avatar_url: "mxc://example.org/abc")
      last(client)[2].should == {avatar_url: "mxc://example.org/abc"}
    end
  end
