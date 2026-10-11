# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/store"

describe Async::Matrix::E2EE::Store do
  let(:store) {subject.new}

  let(:room_id) {"!room:localhost"}

  with "#remember" do
    it "holds a session for the room it was shared for" do
      store.remember(room_id, session_id: "s1", sender: "@bob:localhost")

      expect(store).to be(:session?, room_id, "s1")
    end

    # A session ID is unique to the device which made it, not to the room, so both are needed to tell one from another.
    it "does not hold that session for another room" do
      store.remember(room_id, session_id: "s1", sender: "@bob:localhost")

      expect(store).not.to be(:session?, "!other:localhost", "s1")
    end

    it "holds nothing it was not given" do
      expect(store).not.to be(:session?, room_id, "s1")
    end

    it "notes who shared it" do
      store.remember(room_id, session_id: "s1", sender: "@bob:localhost")

      expect(store.sessions[[room_id, "s1"]][:sender]).to be == "@bob:localhost"
    end
  end

  with "#refuse" do
    # A sender which deliberately withholds a key says why, and that is worth showing rather than reporting the event as broken.
    it "notes why a session was refused" do
      store.refuse(room_id, session_id: "s1", code: "m.unverified")

      expect(store.refused(room_id, "s1")).to be == "m.unverified"
    end

    it "answers nothing for a session which was not refused" do
      expect(store.refused(room_id, "s1")).to be_nil
    end

    it "does not make a refused session a held one" do
      store.refuse(room_id, session_id: "s1", code: "m.unverified")

      expect(store).not.to be(:session?, room_id, "s1")
    end
  end

  with "#defer" do
    # A key can arrive after the events it unlocks, so an event which cannot be read is kept rather than lost.
    it "keeps the events which are waiting for a session" do
      store.defer(room_id, session_id: "s1", event: :first)
      store.defer(room_id, session_id: "s1", event: :second)

      expect(store.deferred_count).to be == 2
      expect(store.deferred(room_id, "s1")).to be == [:first, :second]
    end

    it "releases them once, because they are read when the key arrives" do
      store.defer(room_id, session_id: "s1", event: :first)
      store.deferred(room_id, "s1")

      expect(store.deferred(room_id, "s1")).to be == []
      expect(store.deferred_count).to be == 0
    end

    it "keeps the events of each session apart" do
      store.defer(room_id, session_id: "s1", event: :first)
      store.defer(room_id, session_id: "s2", event: :second)

      expect(store.deferred(room_id, "s1")).to be == [:first]
      expect(store.deferred_count).to be == 1
    end

    it "answers nothing for a session nothing waited on" do
      expect(store.deferred(room_id, "s1")).to be == []
    end
  end
end
