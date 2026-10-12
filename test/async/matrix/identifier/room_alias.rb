# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/room_alias"

describe Async::Matrix::Identifier::RoomAlias do
  with ".parse" do
    it "reads the localpart and the server name" do
      alias_ = subject.parse("#general:example.com")

      expect(alias_.localpart).to be == "general"
      expect(alias_.server_name.to_s).to be == "example.com"
    end

    # Unlike a user ID, an alias localpart is any UTF-8 but a colon and NUL.
    it "reads a localpart outside ASCII" do
      expect(subject.parse("#général:example.com").localpart).to be == "général"
    end

    it "refuses an alias with no server name, which is the server to ask about it" do
      expect{subject.parse("#general")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end

    it "refuses another kind's sigil" do
      expect{subject.parse("!abc:example.com")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#to_s" do
    it "writes back what it read" do
      expect(subject.parse("#général:example.com:8448").to_s).to be == "#général:example.com:8448"
    end
  end
end
