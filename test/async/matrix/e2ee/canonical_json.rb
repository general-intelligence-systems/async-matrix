# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/canonical_json"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::CanonicalJSON do
  include Async::Matrix::E2EEContext

  # The device keys as the homeserver answers with them, which is the object a signature is checked over.
  let(:published) do
    machine.publish!

    client.keys.query_keys({user_id => []}).devices_of(user_id)[machine.device_id.to_sym]
  end

  with ".dump" do
    it "sorts keys, however they were given" do
      expect(subject.dump({b: 1, a: 2})).to be == %({"a":2,"b":1})
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

    # The server returns the keys in whatever order it stored them, and a signature over them must still match.
    it "is the same for the keys we sent and the keys the server answered with" do
      expect(subject.dump(published[:keys])).to be == subject.dump(machine.device_keys[:keys])
    end
  end

  with ".for_signing" do
    # A signature cannot cover itself, and `unsigned` is whatever the server chose to add.
    it "leaves out the fields a signature does not cover" do
      expect(subject.for_signing({a: 1, signatures: {}, unsigned: {age: 10}})).to be == %({"a":1})
      expect(subject.for_signing({"a" => 1, "signatures" => {}, "unsigned" => {}})).to be == %({"a":1})
    end

    # The server adds `unsigned` to what it stored, so a signature made before it was added must still verify.
    it "verifies a signature over what the homeserver answered with" do
      signature = published[:signatures][user_id.to_sym][:"ed25519:#{machine.device_id}"]

      expect(published).to be(:key?, :unsigned)
      expect(crypto.verify(published, key: crypto.identity_keys[:ed25519], signature: signature)).to be == true
    end

    it "signs the keys rather than the signatures over them" do
      expect(subject.for_signing(published)).not.to be(:include?, "signatures")
      expect(subject.for_signing(published)).not.to be(:include?, "unsigned")
    end
  end
end
