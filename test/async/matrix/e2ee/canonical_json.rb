# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "digest"
require "json"
require "openssl"

require "async/matrix/e2ee/canonical_json"
require "async/matrix/server_key"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::CanonicalJSON do
  # The test values the appendices offer "to assist in the development of compatible implementations".
  #
  # Each is the JSON the specification gives, and the bytes it says must be produced.
  VECTORS = {
    %({}) => %({}),
    %({"one":1,"two":"Two"}) => %({"one":1,"two":"Two"}),
    %({"b":"2","a":"1"}) => %({"a":"1","b":"2"}),
    %({"auth":{"success":true,"mxid":"@john.doe:example.com","profile":{"display_name":"John Doe","three_pids":[{"medium":"email","address":"john.doe@example.org"},{"medium":"msisdn","address":"123456789"}]}}}) => %({"auth":{"mxid":"@john.doe:example.com","profile":{"display_name":"John Doe","three_pids":[{"address":"john.doe@example.org","medium":"email"},{"address":"123456789","medium":"msisdn"}]},"success":true}}),
    %({"a":"日本語"}) => %({"a":"日本語"}),
    %({"本":2,"日":1}) => %({"日":1,"本":2}),
    %({"a":"\\u65E5"}) => %({"a":"日"}),
    %({"a":null}) => %({"a":null}),
    %({"a":-0,"b":1e10}) => %({"a":0,"b":10000000000}),
  }.freeze

  # The device keys `matrix-rust-sdk` checks a signature over, in `crates/matrix-sdk-crypto/src/olm/utility.rs`.
  #
  # The signature was made by another implementation, so it only verifies if our canonical form agrees with theirs byte for byte.
  let(:signed_device_keys) do
    JSON.parse(<<~JSON, symbolize_names: true)
      {
        "device_id": "GBEWHQOYGS",
        "algorithms": ["m.olm.v1.curve25519-aes-sha2", "m.megolm.v1.aes-sha2"],
        "keys": {
          "curve25519:GBEWHQOYGS": "F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU",
          "ed25519:GBEWHQOYGS": "n469gw7zm+KW+JsFIJKnFVvCKU14HwQyocggcCIQgZY"
        },
        "signatures": {
          "@example:localhost": {
            "ed25519:GBEWHQOYGS": "OlF2REsqjYdAfr04ONx8VS/5cB7KjrWYRlLF4eUm2foAiQL/RAfsjsa2JXZeoOHh6vEualZHbWlod49OewVqBg"
          }
        },
        "unsigned": {"device_display_name": "Weechat-Matrix-rs"},
        "user_id": "@example:localhost"
      }
    JSON
  end

  with "the specification's examples" do
    VECTORS.each do |given, canonical|
      it "writes #{given} as #{canonical}" do
        expect(subject.dump(JSON.parse(given))).to be == canonical
      end
    end
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

    # `ruma`'s own `to_string` case, which is the shortest statement that nothing is reordered but the keys.
    it "writes an object of strings as one line" do
      expect(subject.dump({city: "London", street: "10 Downing Street"})).to be == %({"city":"London","street":"10 Downing Street"})
    end

    # `ruma`'s `to_canonical_value_success`, less the parts which are Rust's serde rather than the encoding.
    it "writes every kind of value JSON has" do
      object = {string: "string", array: [0, 1, 2], boolean: true, object: {foo: "Foo", bar: "bar"}, null: nil}

      expect(subject.dump(object)).to be == %({"array":[0,1,2],"boolean":true,"null":null,"object":{"bar":"bar","foo":"Foo"},"string":"string"})
    end

    # `ruma`'s `serialize_canon`: the canonical form of the canonical form is the same bytes again.
    it "is stable when read back and written again" do
      once = subject.dump({a: [1, 2, 3], other: {stuff: "hello"}, string: "Thing"})

      expect(subject.dump(JSON.parse(once))).to be == once
    end

    # The specification forbids them, because no two implementations would agree on how to write one.
    it "refuses a float" do
      expect{subject.dump({a: 1.5})}.to raise_exception(ArgumentError)
    end

    # The specification's last example writes `1e10` as an integer, so a float which carries one is read as it.
    #
    # `ruma`'s `to_canonical_value_invalid_type` refuses this instead, which its own suite cannot reconcile with that example.
    it "writes a float which carries a whole number as that number" do
      expect(subject.dump({foo: 10.0})).to be == %({"foo":10})
      expect(subject.dump({foo: -0.0})).to be == %({"foo":0})
    end

    # `python-canonicaljson`'s `test_invalid_float_values`.
    it "refuses a float which carries no number at all" do
      expect{subject.dump({a: Float::NAN})}.to raise_exception(ArgumentError)
      expect{subject.dump({a: Float::INFINITY})}.to raise_exception(ArgumentError)
      expect{subject.dump({a: -Float::INFINITY})}.to raise_exception(ArgumentError)
    end

    # A float which carries a whole number too large to write is still too large to write.
    it "refuses a float outside the range the specification allows" do
      expect{subject.dump({a: 1e30})}.to raise_exception(ArgumentError)
    end

    # `ruma`'s `to_canonical_value_out_of_range_int`: an integer outside the range IEEE doubles represent exactly cannot be signed, because the implementation checking the signature will not read back what we wrote.
    it "refuses an integer outside the range the specification allows" do
      expect{subject.dump({foo: 2**53})}.to raise_exception(ArgumentError)
      expect{subject.dump({foo: -(2**53)})}.to raise_exception(ArgumentError)
    end

    it "writes the largest integers the specification allows" do
      expect(subject.dump({a: (2**53) - 1})).to be == %({"a":9007199254740991})
      expect(subject.dump({a: -((2**53) - 1)})).to be == %({"a":-9007199254740991})
    end

    # `ruma`'s `to_canonical_value_invalid_object_key_type`, which refuses a key that is not a string.
    it "refuses a key which is not a name" do
      expect{subject.dump({4 => "bar"})}.to raise_exception(ArgumentError)
      expect{subject.dump({true => "bar"})}.to raise_exception(ArgumentError)
    end

    # `ruma`'s `to_canonical_value_duplicate_object_key`: two keys which become one name would silently lose a value.
    it "refuses two keys which are the same name" do
      expect{subject.dump({:a => 1, "a" => 2})}.to raise_exception(ArgumentError)
    end

    # `python-canonicaljson`'s `test_unknown_type`: the grammar has seven kinds of value, and this is none of them.
    it "refuses a value the grammar cannot write" do
      expect{subject.dump({a: Object.new})}.to raise_exception(ArgumentError)
      expect{subject.dump({a: Rational(1, 2)})}.to raise_exception(ArgumentError)
    end
  end

  # `python-canonicaljson`'s `test_ascii` and `test_encode_canonical`, which measure the escapes against the grammar.
  with "the characters the grammar escapes" do
    # The seven which have a shorthand, which is shorter than the four hex digits and so is the one to write.
    SHORTHANDS = {0x08 => %q(\\b), 0x09 => %q(\\t), 0x0a => %q(\\n), 0x0c => %q(\\f), 0x0d => %q(\\r), 0x22 => %q(\\"), 0x5c => %q(\\\\)}.freeze

    # Every other ASCII control character, which has no shorthand to use.
    HEX_ESCAPED = ((0x00..0x07).to_a + [0x0b] + (0x0e..0x1f).to_a).freeze

    # The printable ASCII, less the quotation mark and the reverse solidus, which the grammar passes through.
    UNESCAPED = ([0x20, 0x21] + (0x23..0x5b).to_a + (0x5d..0x7d).to_a).freeze

    it "writes the control characters which have a shorthand" do
      SHORTHANDS.each do |codepoint, escape|
        expect(subject.dump(codepoint.chr)).to be == %("#{escape}")
      end
    end

    it "writes every other control character as four lowercase hex digits" do
      HEX_ESCAPED.each do |codepoint|
        expect(subject.dump(codepoint.chr)).to be == format(%("\\u%04x"), codepoint)
      end
    end

    it "writes the printable characters as themselves" do
      UNESCAPED.each do |codepoint|
        expect(subject.dump(codepoint.chr)).to be == %("#{codepoint.chr}")
      end
    end

    it "writes a string which already looks like an escape" do
      expect(subject.dump("\\u1234")).to be == %("\\\\u1234")
    end

    it "writes characters outside ASCII as UTF-8 rather than escapes" do
      expect(subject.dump({"la merde amusée" => "💩"})).to be == %({"la merde amusée":"💩"})
    end

    # The two separators which some encoders escape to survive being pasted into JavaScript.
    it "writes the line and paragraph separators as themselves" do
      expect(subject.dump({spaces: "\u2028 \u2029"})).to be == %({"spaces":"\u2028 \u2029"})
    end
  end

  with ".for_signing" do
    # A signature cannot cover itself, and `unsigned` is whatever the server chose to add.
    it "leaves out the fields a signature does not cover" do
      expect(subject.for_signing({a: 1, signatures: {}, unsigned: {age: 10}})).to be == %({"a":1})
      expect(subject.for_signing({"a" => 1, "signatures" => {}, "unsigned" => {}})).to be == %({"a":1})
    end

    # Only the top level is stripped: a nested object named `signatures` is part of what is signed.
    it "keeps a nested field which shares their name" do
      expect(subject.for_signing({a: {signatures: 1, unsigned: 2}})).to be == %({"a":{"signatures":1,"unsigned":2}})
    end

    it "writes the device keys another implementation signed" do
      expect(subject.for_signing(signed_device_keys)).to be == %({"algorithms":["m.olm.v1.curve25519-aes-sha2","m.megolm.v1.aes-sha2"],"device_id":"GBEWHQOYGS","keys":{"curve25519:GBEWHQOYGS":"F8QhZ0Z1rjtWrQOblMDgZtEX5x1UrG7sZ2Kk3xliNAU","ed25519:GBEWHQOYGS":"n469gw7zm+KW+JsFIJKnFVvCKU14HwQyocggcCIQgZY"},"user_id":"@example:localhost"})
    end
  end

  # What the encoding is for: bytes two implementations can both sign and check.
  with "a signature over the canonical form" do
    # The key `matrix-rust-sdk`'s own signature case was made with, which is the device's own ed25519 key.
    let(:device_key) do
      OpenSSL::PKey.new_raw_public_key("ed25519", Base64.decode64(signed_device_keys[:keys][:"ed25519:GBEWHQOYGS"]))
    end

    let(:key) {Async::Matrix::ServerKey.parse("ed25519 1 SnDmunk28k36o2ibXNWobfWLBguwZDy3xFsNprjwl+c")}

    let(:other_key) {Async::Matrix::ServerKey.parse("ed25519 2 YW5vdGhlciBzZWVkIHdoaWNoIGlzIHRoaXJ0eSB0d28")}

    # `matrix-rust-sdk`'s `signature_test`: a signature made by another implementation, over keys a homeserver answered with.
    it "verifies a signature another implementation made" do
      signature = signed_device_keys[:signatures][:"@example:localhost"][:"ed25519:GBEWHQOYGS"]

      verified = device_key.verify(nil, Base64.decode64(signature), subject.for_signing(signed_device_keys))

      expect(verified).to be == true
    end

    # `ruma`'s `verify_canonical_json_bytes_success`.
    it "verifies a signature we made ourselves" do
      object = {foo: "bar", bat: "baz"}

      expect(key.verify(object, key.sign(object))).to be == true
    end

    # `ruma`'s `verify_canonical_json_bytes_wrong_key`.
    it "refuses a signature another key made" do
      object = {foo: "bar", bat: "baz"}

      expect(other_key.verify(object, key.sign(object))).to be == false
    end

    # The order the fields were given in is not signed, so the same object written differently verifies.
    it "verifies whatever order the fields arrived in" do
      signature = key.sign({foo: "bar", bat: "baz"})

      expect(key.verify({bat: "baz", foo: "bar"}, signature)).to be == true
    end

    # A signature is made before `signatures` and `unsigned` exist, and must still verify once they do.
    it "verifies after the signature and the server's own fields were added" do
      object = {foo: "bar"}
      signature = key.sign(object)
      answered = object.merge(signatures: {"example.com": {key.id => signature}}, unsigned: {age: 10})

      expect(key.verify(answered, signature)).to be == true
    end
  end

  # `synapse`'s `tests/crypto/test_event_signing.py`, whose key and events are fixed so that its output is too.
  #
  # Both the content hash and the signature are taken over the canonical form, so they only come out right if ours matches Synapse's byte for byte.
  with "the event hashes and signatures Synapse wrote" do
    # The seed `EventSigningTestCase` signs with, so that what it wrote can be written again.
    let(:key) {Async::Matrix::ServerKey.parse("ed25519 1 YJDBA9Xnr2sVqXD9Vj7XVUnmFZcZrlw8Md7kMW+3XA1")}

    # The hash of the event as it was sent, which is every field but the ones a server adds.
    #
    # @parameter event [Hash] the event to hash.
    # @returns [String] the hash, as unpadded base64.
    def content_hash(event)
      Async::Matrix::ServerKey.encode(Digest::SHA256.digest(Async::Matrix::E2EE::CanonicalJSON.dump(event.reject{|key, _| HASHED.include?(key)})))
    end

    # The fields `compute_content_hash` drops, which are the ones no sender wrote.
    HASHED = [:age_ts, :unsigned, :signatures, :hashes, :outlier, :destinations].freeze

    # `test_sign_minimal`, whose event carries nothing but the fields every event has.
    let(:minimal) do
      {event_id: "$0:domain", origin_server_ts: 1000000, signatures: {}, type: "X", content: {}, unsigned: {age_ts: 1000000}}
    end

    # `test_sign_message`, whose event carries a body, a room and a sender as well.
    let(:message) do
      {content: {body: "Here is the message content"}, event_id: "$0:domain", origin_server_ts: 1000000, type: "m.room.message", room_id: "!r:domain", sender: "@u:domain", signatures: {}, unsigned: {age_ts: 1000000}}
    end

    it "hashes the minimal event to what Synapse hashed it to" do
      expect(content_hash(minimal)).to be == "mq4QfPPpC+QsBd6eqfVsmJIEz8uvMSVK0+AU67PLESk"
    end

    it "hashes the message event to what Synapse hashed it to" do
      expect(content_hash(message)).to be == "rDCeYBepPlI891h/RkI2/Lkf9bt7u0TxFku4tMs7WKk"
    end

    # The signature covers the redacted event, which for room version 1 keeps no content at all from an unknown type.
    it "signs the minimal event as Synapse signed it" do
      redacted = {content: {}, event_id: "$0:domain", hashes: {sha256: content_hash(minimal)}, origin_server_ts: 1000000, signatures: {}, type: "X"}

      expect(key.sign(redacted)).to be == "18rGIkd4JJXxw9m+1j3BtN+TmqmLip4VHvFbyXLngpBLXOqbxlQViQABRzep2cODQ2aa5FnFgz+Llt2P03WiAw"
    end

    # A message's body is not kept by redaction either, so the content is empty here too.
    it "signs the message event as Synapse signed it" do
      redacted = {content: {}, event_id: "$0:domain", hashes: {sha256: content_hash(message)}, origin_server_ts: 1000000, room_id: "!r:domain", sender: "@u:domain", signatures: {}, type: "m.room.message"}

      expect(key.sign(redacted)).to be == "Ay4aj2b5oJ1k8INYZ9n3KnszCflM0emwcmQQ7vxpbdcSv9bkJxIZdWX1IJllcZLq89+D3sSabE+vqPtZs9akDw"
    end
  end

  with "an encrypting client" do
    include Async::Matrix::E2EEContext

    # The device keys as the homeserver answers with them, which is the object a signature is checked over.
    let(:answered) do
      machine.publish!

      client.keys.query_keys({user_id => []}).devices_of(user_id)[machine.device_id.to_sym]
    end

    # The server returns the keys in whatever order it stored them, and a signature over them must still match.
    it "is the same for the keys we sent and the keys the server answered with" do
      expect(subject.dump(answered[:keys])).to be == subject.dump(machine.device_keys[:keys])
    end

    # The server adds `unsigned` to what it stored, so a signature made before it was added must still verify.
    it "verifies a signature over what the homeserver answered with" do
      signature = answered[:signatures][user_id.to_sym][:"ed25519:#{machine.device_id}"]

      expect(answered).to be(:key?, :unsigned)
      expect(crypto.verify(answered, key: crypto.identity_keys[:ed25519], signature: signature)).to be == true
    end

    it "signs the keys rather than the signatures over them" do
      expect(subject.for_signing(answered)).not.to be(:include?, "signatures")
      expect(subject.for_signing(answered)).not.to be(:include?, "unsigned")
    end
  end
end
