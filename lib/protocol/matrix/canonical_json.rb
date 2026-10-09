# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

require_relative "error"

module Protocol
  module Matrix
    # Canonical JSON: "the shortest UTF-8 JSON encoding with dictionary keys
    # lexicographically sorted by Unicode codepoint."
    #
    # https://spec.matrix.org/latest/appendices/#canonical-json
    #
    # This is not a formatting preference. A signature is computed over these
    # exact bytes, so any disagreement about whitespace, key order or number
    # formatting produces a signature every other implementation rejects — and
    # the failure appears at the far end, as somebody else's device refusing our
    # keys, with nothing locally to see.
    #
    # The rules, each of which is enforced below:
    #
    #   * dictionary keys sorted by Unicode codepoint
    #   * no insignificant whitespace (separators are "," and ":")
    #   * code-points outside ASCII encoded as UTF-8, NOT as \u escapes
    #   * integers only, in [-(2**53)+1, (2**53)-1], no exponents, no decimals
    #   * "Float values are not permitted by this encoding"
    #   * negative zero MUST NOT appear
    module CanonicalJson
      MAXIMUM_INTEGER = (2**53) - 1
      MINIMUM_INTEGER = -(2**53) + 1

      # The two keys a signature never covers: "The `unsigned` object and the
      # `signatures` object are not covered by the signature."
      EXCLUDED_FROM_SIGNATURE = %w[signatures unsigned].freeze

      class Error < Protocol::Matrix::Error; end

      # @returns [String] the canonical encoding of +value+.
      def self.encode(value)
        JSON.generate(canonicalize(value))
      end

      # Sort, stringify and check, recursively.
      #
      # Ruby's String#<=> compares bytes, and UTF-8 byte order is codepoint
      # order, so a plain sort IS the codepoint sort the spec asks for. That
      # equivalence is the whole reason this is three lines rather than a
      # custom comparator.
      #
      # Keys are stringified BEFORE sorting, not read back out of the hash
      # afterwards: `h[k] || h[k.to_sym]` would mishandle a stored `false`.
      def self.canonicalize(value)
        case value
        when Hash
          value.to_h { |key, nested| [key.to_s, canonicalize(nested)] }.sort.to_h
        when Array
          value.map { |nested| canonicalize(nested) }
        when Float
          raise Error, "float values are not permitted by canonical JSON: #{value.inspect}"
        when Integer
          check_integer(value)
        when Symbol
          value.to_s
        else
          value
        end
      end

      def self.check_integer(value)
        if value > MAXIMUM_INTEGER || value < MINIMUM_INTEGER
          raise Error,
            "integer out of canonical JSON range [#{MINIMUM_INTEGER}, #{MAXIMUM_INTEGER}]: #{value}"
        end

        value
      end

      # The object as it is signed: everything except the two keys a signature
      # does not cover. Returns a copy; the original is untouched, because the
      # caller still needs its signatures.
      def self.signable(object)
        object.reject { |key, _| EXCLUDED_FROM_SIGNATURE.include?(key.to_s) }
      end

      # The exact bytes a signature is computed over.
      def self.signable_bytes(object)
        encode(signable(object))
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::CanonicalJson" do
    def encode(value) = Protocol::Matrix::CanonicalJson.encode(value)

    # The worked examples from https://spec.matrix.org/latest/appendices/#canonical-json
    it "matches the spec's empty object example" do
      encode({}).should == "{}"
    end

    it "matches the spec's key ordering example" do
      encode({"one" => 1, "two" => "Two"}).should == '{"one":1,"two":"Two"}'
      encode({"b" => "2", "a" => "1"}).should == '{"a":"1","b":"2"}'
    end

    it "matches the spec's nested example" do
      encode({"auth" => {"success" => true, "mxid" => "@john.doe:example.com"}})
        .should == '{"auth":{"mxid":"@john.doe:example.com","success":true}}'
    end

    # "Encode code-points outside of ASCII as UTF-8 rather than \u escapes."
    it "emits non-ASCII as UTF-8 rather than escapes" do
      encode({"a" => "日本語"}).should == '{"a":"日本語"}'
    end

    it "keeps an escape the JSON grammar requires" do
      encode({"a" => "quote\"and\\slash"}).should == '{"a":"quote\"and\\\\slash"}'
    end

    # Keys sort by Unicode codepoint, which for UTF-8 is byte order.
    it "sorts keys by codepoint, not by locale or length" do
      encode({"Z" => 1, "a" => 2, "A" => 3, "z" => 4})
        .should == '{"A":3,"Z":1,"a":2,"z":4}'
      encode({"é" => 1, "z" => 2}).should == '{"z":2,"é":1}'
    end

    it "sorts nested objects too" do
      encode({"b" => {"d" => 1, "c" => 2}, "a" => 3})
        .should == '{"a":3,"b":{"c":2,"d":1}}'
    end

    # Arrays are ordered data: their order is the sender's, not ours to sort.
    it "leaves array order alone" do
      encode({"a" => [3, 1, 2]}).should == '{"a":[3,1,2]}'
    end

    it "has no insignificant whitespace anywhere" do
      encoded = encode({"a" => {"b" => [1, 2]}, "c" => "d"})

      encoded.should == '{"a":{"b":[1,2]},"c":"d"}'
      encoded.include?(" ").should == false
    end

    it "stringifies symbol keys and values" do
      encode({a: :b}).should == '{"a":"b"}'
    end

    it "encodes null, true and false" do
      encode({"a" => nil, "b" => true, "c" => false}).should == '{"a":null,"b":true,"c":false}'
    end

    # "Float values are not permitted by this encoding."
    it "refuses floats, including ones that look like integers" do
      lambda { encode({"a" => 1.5}) }.should.raise(Protocol::Matrix::CanonicalJson::Error)
      lambda { encode({"a" => 1.0}) }.should.raise(Protocol::Matrix::CanonicalJson::Error)
      lambda { encode({"a" => [1.0]}) }.should.raise(Protocol::Matrix::CanonicalJson::Error)
    end

    # "Numbers in the JSON must be integers in the range [-(2**53)+1, (2**53)-1]"
    it "accepts the integer range boundaries" do
      encode({"a" => (2**53) - 1}).should == '{"a":9007199254740991}'
      encode({"a" => -(2**53) + 1}).should == '{"a":-9007199254740991}'
    end

    it "refuses integers outside the range" do
      lambda { encode({"a" => 2**53}) }.should.raise(Protocol::Matrix::CanonicalJson::Error)
      lambda { encode({"a" => -(2**53)}) }.should.raise(Protocol::Matrix::CanonicalJson::Error)
    end

    # ── What a signature covers ───────────────────────────────────────────────

    # "The `unsigned` object and the `signatures` object are not covered by the
    # signature."
    it "excludes signatures and unsigned from the signable form" do
      object = {
        "a" => 1,
        "signatures" => {"@alice:example.com" => {"ed25519:DEV" => "sig"}},
        "unsigned" => {"age" => 100},
      }

      Protocol::Matrix::CanonicalJson.signable(object).should == {"a" => 1}
      Protocol::Matrix::CanonicalJson.signable_bytes(object).should == '{"a":1}'
    end

    it "leaves the original object untouched" do
      object = {"a" => 1, "signatures" => {"x" => "y"}}
      Protocol::Matrix::CanonicalJson.signable(object)

      object.key?("signatures").should == true
    end

    it "excludes them whether the keys are strings or symbols" do
      Protocol::Matrix::CanonicalJson.signable({:a => 1, :signatures => {}, :unsigned => {}})
        .should == {:a => 1}
    end
  end
