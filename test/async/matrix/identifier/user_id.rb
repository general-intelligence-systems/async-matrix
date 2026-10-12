# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/user_id"

describe Async::Matrix::Identifier::UserID do
  with ".parse" do
    it "reads the localpart and the server name" do
      user = subject.parse("@alice:example.com")

      expect(user.localpart).to be == "alice"
      expect(user.server_name.to_s).to be == "example.com"
      expect(user.historical?).to be == false
    end

    # The grammar v1.8 settled on, whose punctuation is the whole of what it allows.
    it "reads every character the grammar allows" do
      expect(subject.parse("@a0.b-c=d_e/f+g:example.com").historical?).to be == false
    end

    it "refuses a user ID with no server name" do
      expect{subject.parse("@alice")}.to raise_exception(Async::Matrix::InvalidIdentifierError)
    end
  end

  with "#historical?" do
    # A client MUST accept these, because there are users and room histories which carry them.
    it "reads a localpart only an older specification allowed" do
      ["@Alice:example.com", "@a b:example.com", "@üser:example.com", "@:example.com"].each do |string|
        expect(subject.parse(string).historical?).to be == true
      end
    end
  end

  with "#compliant?" do
    it "is compliant where the localpart is printable ASCII" do
      expect(subject.parse("@Alice:example.com").compliant?).to be == true
    end

    # A server SHOULD NOT name these to a client outside an event, so a caller can tell.
    it "is not compliant where the localpart is empty or beyond printable ASCII" do
      expect(subject.parse("@:example.com").compliant?).to be == false
      expect(subject.parse("@a b:example.com").compliant?).to be == false
      expect(subject.parse("@üser:example.com").compliant?).to be == false
    end
  end

  with ".mapped" do
    it "downcases the letters which have no place in a localpart" do
      expect(subject.mapped("Alice", server_name: "example.com").to_s).to be == "@alice:example.com"
    end

    # The appendices' own examples of what a byte outside the grammar is written as.
    it "writes a byte outside the grammar as its hexadecimal value" do
      expect(subject.mapped("#", server_name: "example.com").localpart).to be == "=23"
      expect(subject.mapped("á", server_name: "example.com").localpart).to be == "=c3=a1"
    end

    # Equals is in the grammar, but it introduces an escape, so it is escaped itself.
    it "escapes the character which introduces an escape" do
      expect(subject.mapped("a=b", server_name: "example.com").localpart).to be == "a=3db"
    end

    it "keeps what the grammar already allows" do
      expect(subject.mapped("a0.b-c_d/e+f", server_name: "example.com").localpart).to be == "a0.b-c_d/e+f"
    end

    # A bridge which must tell two names apart keeps the case, by writing the letter after an underscore.
    it "keeps case where it is asked to" do
      expect(subject.mapped("A", server_name: "example.com", escape: true).localpart).to be == "_a"
      expect(subject.mapped("_", server_name: "example.com", escape: true).localpart).to be == "__"
      expect(subject.mapped("Alice_Smith", server_name: "example.com", escape: true).localpart).to be == "_alice___smith"
    end

    it "maps onto a localpart the current grammar allows" do
      expect(subject.mapped("Ünïcode Name!", server_name: "example.com").historical?).to be == false
    end
  end
end
