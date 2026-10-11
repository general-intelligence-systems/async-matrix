# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/canonical_json"

describe Async::Matrix::E2EE::CanonicalJSON do
  with ".dump" do
    it "sorts keys, however they were given" do
      expect(subject.dump({b: 1, a: 2})).to be == %({"a":2,"b":1})
    end

    it "sorts the keys of a nested object too" do
      expect(subject.dump({z: {b: 1, a: 2}})).to be == %({"z":{"a":2,"b":1}})
    end

    it "sorts objects within an array, but keeps the array's own order" do
      expect(subject.dump({a: [{d: 1, c: 2}, {b: 3}]})).to be == %({"a":[{"c":2,"d":1},{"b":3}]})
    end

    it "writes no insignificant whitespace" do
      expect(subject.dump({a: 1, b: [1, 2]})).to be == %({"a":1,"b":[1,2]})
    end

    # The specification forbids them, because no two implementations would agree on how to write one.
    it "refuses a float" do
      expect{subject.dump({a: 1.5})}.to raise_exception(ArgumentError)
    end

    it "accepts an integer, a string, a boolean and nil" do
      expect(subject.dump({a: 1, b: "x", c: true, d: nil})).to be == %({"a":1,"b":"x","c":true,"d":null})
    end
  end

  with ".for_signing" do
    # A signature cannot cover itself, and `unsigned` is whatever the server chose to add.
    it "leaves out the fields a signature does not cover" do
      object = {a: 1, signatures: {"@alice:localhost" => {}}, unsigned: {age: 10}}

      expect(subject.for_signing(object)).to be == %({"a":1})
    end

    it "leaves out string keys as well as symbols" do
      expect(subject.for_signing({"a" => 1, "signatures" => {}, "unsigned" => {}})).to be == %({"a":1})
    end

    it "is the canonical form of everything else" do
      expect(subject.for_signing({b: 1, a: 2})).to be == subject.dump({a: 2, b: 1})
    end
  end
end
