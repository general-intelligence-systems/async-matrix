# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/generic"
require "async/matrix/identifier/user_id"
require "async/matrix/identifier/room_id"

describe Async::Matrix::Identifier::Generic do
  # The base class has no sigil of its own, so its behaviour is read through a kind which has one.
  let(:kind) {Async::Matrix::Identifier::UserID}

  with ".split" do
    # A localpart holds no colon, so the first one begins the server name however many follow it.
    it "divides at the first colon, not the last" do
      expect(kind.split("@alice:example.com:8448")).to be == ["alice", "example.com:8448"]
    end

    it "answers no server name where the string carries none" do
      expect(Async::Matrix::Identifier::RoomID.split("!abc")).to be == ["abc", nil]
    end

    it "refuses a sigil which belongs to another kind" do
      expect{kind.split("!abc:example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end

    it "refuses a string with no sigil at all" do
      expect{kind.split("alice:example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#validate" do
    # The limit is on bytes rather than characters, because it comes from the size of an event.
    it "refuses an identifier longer than two hundred and fifty five bytes" do
      expect{kind.new("a" * 243, "example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
      expect(kind.new("a" * 242, "example.com").to_s.bytesize).to be == 255
    end

    it "counts a multi-byte localpart in bytes" do
      expect{Async::Matrix::Identifier::RoomAlias.new("é" * 122, "example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end

    it "refuses a localpart holding NUL" do
      expect{Async::Matrix::Identifier::RoomID.new("a\u0000b")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end

    it "refuses a localpart which is not valid UTF-8" do
      expect{Async::Matrix::Identifier::RoomID.new("\xff".b)}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#to_s" do
    it "writes the sigil, the localpart and the server name" do
      expect(kind.new("alice", "example.com").to_s).to be == "@alice:example.com"
    end

    # Standing in for a string is what lets an identifier be passed to an endpoint which interpolates one.
    it "stands in for a string" do
      expect("#{kind.parse("@alice:example.com")}").to be == "@alice:example.com"
      expect(String.try_convert(kind.parse("@alice:example.com"))).to be == "@alice:example.com"
    end
  end

  with "#==" do
    it "is equal to the same identifier of the same kind" do
      expect(kind.parse("@alice:example.com")).to be == kind.parse("@alice:example.com")
    end

    # The localpart and the server name are not enough: the kind is part of what an identifier is.
    it "is not equal to the same string read as another kind" do
      expect(kind.parse("@alice:example.com")).not.to be == Async::Matrix::Identifier::RoomID.parse("!alice:example.com")
    end

    it "can be used as a key" do
      expect({kind.parse("@alice:example.com") => 1}[kind.parse("@alice:example.com")]).to be == 1
    end
  end

  with ".valid?" do
    it "answers rather than raising" do
      expect(kind.valid?("@alice:example.com")).to be == true
      expect(kind.valid?("!abc:example.com")).to be == false
    end
  end
end
