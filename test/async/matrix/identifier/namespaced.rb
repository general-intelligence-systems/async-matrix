# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/identifier/namespaced"

describe Async::Matrix::Identifier::Namespaced do
  with ".valid?" do
    it "accepts a name which begins with a letter and carries the characters allowed" do
      ["m.room.message", "com.example.identifier", "a", "a-b_c.d0"].each do |string|
        expect(subject.valid?(string)).to be == true
      end
    end

    # Lower case only, so that nothing turns on case, and nothing begins with a digit or a dot.
    it "refuses a name outside the grammar" do
      ["M.Thing", "1abc", ".abc", "-abc", "com.example/thing", "", "a" * 256].each do |string|
        expect(subject.valid?(string)).to be == false
      end
    end
  end

  with ".reserved?" do
    # The specification keeps this prefix, so an implementation names its own thing after its domain.
    it "says which names belong to the specification" do
      expect(subject.reserved?("m.room.message")).to be == true
      expect(subject.reserved?("com.example.identifier")).to be == false
    end
  end
end
