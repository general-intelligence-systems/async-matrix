# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier"

describe Async::Matrix::Identifier do
  # The sigils the appendices name, which is how a string says which kind it is.
  SIGILS = {
    Async::Matrix::Identifier::UserID => "@",
    Async::Matrix::Identifier::RoomID => "!",
    Async::Matrix::Identifier::EventID => "$",
    Async::Matrix::Identifier::RoomAlias => "#",
  }.freeze

  it "gives each kind of identifier the sigil the specification does" do
    SIGILS.each do |kind, sigil|
      expect(kind::SIGIL).to be == sigil
    end
  end

  it "reads each kind from a string which carries its sigil" do
    SIGILS.each do |kind, sigil|
      expect(kind.parse("#{sigil}abc:example.com").sigil).to be == sigil
    end
  end

  # A caller rescuing the library's errors catches a bad identifier with them.
  it "raises an error of the library's own" do
    expect(Async::Matrix::InvalidIdentifierError.ancestors).to be(:include?, Async::Matrix::Error)
  end
end
