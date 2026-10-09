# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "openssl"

module Async
  module Matrix
    module E2EE
      # The key every stored crypto object in this namespace is encrypted with
      # at rest.
      #
      # A "pickle" is vodozemac's serialised snapshot of an Account or a
      # session -- the only way ratchet state survives a restart:
      #
      #   blob    = session.pickle(pickle_key.to_s)
      #   session = E2EE::Session.from_pickle(blob, pickle_key.to_s)
      #
      # This key is what stops a copy of the database being a plaintext dump of
      # the device's identity keys and every room key it holds.
      #
      # IT MUST NEVER CHANGE. Rotate or lose it and every pickle is
      # undecryptable: the Account goes, every Megolm session goes, and all
      # encrypted history becomes permanently unreadable unless server-side key
      # backup happens to hold copies. There is no recovery path and no warning
      # -- the symptom is simply that nothing decrypts any more.
      #
      # SO THE SECRET IS THE APPLICATION'S, not this library's. #derive exists
      # because the shape requirement below catches everyone, not because a gem
      # should own your key material.
      class PickleKey
        # vodozemac wants exactly 32 bytes AND rejects a binary string: hand it
        # raw KDF output and it fails with "expected utf-8, got ASCII-8BIT".
        LENGTH = 32

        # 24 bytes of entropy base64s to exactly 32 ASCII characters, which
        # satisfies both constraints at once -- 32 bytes, valid UTF-8, 192 bits.
        # That arithmetic is the whole reason this class exists.
        DERIVED_BYTES = 24

        DEFAULT_INFO = "matrix device pickle"

        class Error < StandardError; end

        # Derive a key from an application secret.
        #
        # Deterministic: the same secret always yields the same key, which is
        # what makes it survive a restart without being written down anywhere.
        # Use a different `info` to derive unrelated keys from one secret.
        def self.derive(secret, info: DEFAULT_INFO, salt: "")
          if secret.nil? || secret.to_s.empty?
            raise Error, "cannot derive a pickle key from an empty secret"
          end

          new(
            [
              OpenSSL::KDF.hkdf(
                secret.to_s,
                salt:   salt,
                info:   info,
                length: DERIVED_BYTES,
                hash:   "SHA256",
              ),
            ].pack("m0"),
          )
        end

        # Wrap a key you already have -- one derived elsewhere, or read from a
        # secret store.
        #
        # @raises [Error] unless it is exactly 32 bytes and valid UTF-8, because
        #   vodozemac refuses anything else and the failure it gives is obscure.
        def initialize(value)
          @value = value.to_s.dup.force_encoding(Encoding::UTF_8)

          unless @value.bytesize == LENGTH
            raise Error, "a pickle key must be exactly #{LENGTH} bytes, got #{@value.bytesize}"
          end

          unless @value.valid_encoding?
            raise Error, "a pickle key must be valid UTF-8; vodozemac rejects binary strings"
          end

          @value.freeze
        end

        # The key as vodozemac wants it.
        def to_s = @value

        # Never the key itself: a pickle key in a log or an exception message is
        # as bad as one in a repository.
        def inspect = "#<#{self.class.name} [redacted]>"

        def ==(other) = other.is_a?(self.class) && to_s == other.to_s
      end
    end
  end
end

__END__
  describe "Async::Matrix::E2EE::PickleKey" do
    K = Async::Matrix::E2EE::PickleKey

    # The arithmetic this class exists for: 24 bytes of entropy base64s to
    # exactly the 32 ASCII characters vodozemac demands.
    it "derives a key of exactly 32 bytes, valid UTF-8" do
      key = K.derive("an application secret")

      key.to_s.bytesize.should == 32
      key.to_s.encoding.should == Encoding::UTF_8
      key.to_s.valid_encoding?.should == true
    end

    # Deterministic, which is what lets it survive a restart without being
    # written down.
    it "derives the same key from the same secret" do
      K.derive("secret").should == K.derive("secret")
    end

    it "derives different keys from different secrets" do
      K.derive("one").should.not == K.derive("two")
    end

    # One secret, several unrelated keys.
    it "separates keys by info string" do
      K.derive("secret", info: "a").should.not == K.derive("secret", info: "b")
    end

    it "refuses an empty secret" do
      lambda { K.derive("") }.should.raise(Async::Matrix::E2EE::PickleKey::Error)
      lambda { K.derive(nil) }.should.raise(Async::Matrix::E2EE::PickleKey::Error)
    end

    # ── Wrapping an existing key ──────────────────────────────────────────────

    it "accepts a 32-byte key" do
      K.new("k" * 32).to_s.should == "k" * 32
    end

    # The error vodozemac gives for the wrong length is obscure, so this one is
    # not.
    it "refuses a key of the wrong length" do
      lambda { K.new("short") }.should.raise(Async::Matrix::E2EE::PickleKey::Error)
      lambda { K.new("k" * 33) }.should.raise(Async::Matrix::E2EE::PickleKey::Error)
    end

    # "expected utf-8, got ASCII-8BIT" is what raw KDF output gets you.
    it "refuses bytes that are not valid UTF-8" do
      lambda { K.new("\xFF\xFE".b + ("k" * 30)) }
        .should.raise(Async::Matrix::E2EE::PickleKey::Error)
    end

    it "accepts binary-encoded bytes that happen to be valid UTF-8" do
      K.new(("k" * 32).b).to_s.encoding.should == Encoding::UTF_8
    end

    # ── Not leaking ───────────────────────────────────────────────────────────

    # A pickle key in a log is as bad as one in a repository.
    it "never shows the key in inspect" do
      key = K.derive("secret")

      key.inspect.should.not.be.include? key.to_s
      key.inspect.should.be.include? "redacted"
    end

    it "is frozen, so nothing can mutate it in place" do
      K.derive("secret").to_s.frozen?.should == true
    end

    # It belongs beside the objects it encrypts, which is the point of the
    # namespace: every one of these answers #pickle.
    it "sits with the classes whose pickles it protects" do
      [
        Async::Matrix::E2EE::Account,
        Async::Matrix::E2EE::Session,
        Async::Matrix::E2EE::GroupSession,
        Async::Matrix::E2EE::InboundGroupSession,
      ].each { |klass| klass.instance_methods.should.be.include? :pickle }
    end
  end
