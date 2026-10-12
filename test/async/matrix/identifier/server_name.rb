# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/server_name"

describe Async::Matrix::Identifier::ServerName do
  with ".parse" do
    it "reads a DNS name" do
      name = subject.parse("example.com")

      expect(name.host).to be == "example.com"
      expect(name.port).to be_nil
      expect(name.literal?).to be == false
    end

    it "reads a DNS name and a port" do
      name = subject.parse("example.com:8448")

      expect(name.host).to be == "example.com"
      expect(name.port).to be == 8448
    end

    # The grammar allows upper case in a DNS name, whatever a resolver makes of it.
    it "reads a DNS name which is not lower case" do
      expect(subject.parse("Example.COM").host).to be == "Example.COM"
    end

    it "reads a dotted quad" do
      name = subject.parse("1.2.3.4:443")

      expect(name.host).to be == "1.2.3.4"
      expect(name.port).to be == 443
      expect(name.literal?).to be == true
    end

    # An IPv6 literal is written in brackets, which are not part of the address.
    it "reads an IPv6 literal without its brackets" do
      name = subject.parse("[1234:5678::abcd]:5678")

      expect(name.host).to be == "1234:5678::abcd"
      expect(name.port).to be == 5678
      expect(name.bracketed?).to be == true
    end

    it "refuses a name which is not one" do
      ["", "exa mple.com", "example.com:", "example.com:123456", "[::1", "::1"].each do |string|
        expect{subject.parse(string)}.to raise_exception(Async::Matrix::InvalidIdentifierError)
      end
    end
  end

  with "#to_s" do
    # What was read is written back the same way, so a signature over it still matches.
    it "writes back what it read" do
      ["example.com", "example.com:8448", "1.2.3.4", "[::1]:8448"].each do |string|
        expect(subject.parse(string).to_s).to be == string
      end
    end
  end

  with ".for" do
    it "keeps a name it is given" do
      name = subject.parse("example.com")

      expect(subject.for(name)).to be_equal(name)
    end

    it "reads a string it is given" do
      expect(subject.for("example.com")).to be == subject.parse("example.com")
    end
  end

  with ".valid?" do
    it "says whether a string is one" do
      expect(subject.valid?("example.com:8448")).to be == true
      expect(subject.valid?("exa mple.com")).to be == false
    end
  end
end
