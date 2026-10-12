# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/room_id"

describe Async::Matrix::Identifier::RoomID do
  with ".parse" do
    # The form the room versions before v12 use, where the server only kept the namespace apart.
    it "reads a room ID which names the server which created the room" do
      room = subject.parse("!abc123:example.com")

      expect(room.localpart).to be == "abc123"
      expect(room.server_name.to_s).to be == "example.com"
      expect(room.namespaced?).to be == true
    end

    # Room version 12 took the domain out: the room ID is the create event's ID under another sigil.
    it "reads a room ID which carries a hash instead" do
      room = subject.parse("!Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg")

      expect(room.server_name).to be_nil
      expect(room.namespaced?).to be == false
    end

    # A client treats the whole of it as opaque, so a localpart outside the suggested set still reads.
    it "reads a localpart which is not alphanumeric" do
      expect(subject.parse("!a b/c:example.com").localpart).to be == "a b/c"
    end

    it "refuses another kind's sigil" do
      expect{subject.parse("@alice:example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#to_s" do
    it "writes back what it read" do
      ["!abc123:example.com", "!Rqnc-F-dvnEYJTyHq_iKxU2bZ1CI92-kuZq3a5lr5Zg"].each do |string|
        expect(subject.parse(string).to_s).to be == string
      end
    end
  end
end
