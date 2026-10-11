# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "openssl"

require_relative "error"
require_relative "e2ee/canonical_json"

module Async
  module Matrix
    # Raised when a signing key cannot be read.
    class InvalidKeyError < Error
    end

    # The key a homeserver signs for its own server name with.
    #
    # A request is signed rather than carrying a token, and the same key signs events.
    class ServerKey
      # The only algorithm the specification defines for a server key.
      ALGORITHM = "ed25519"

      # How many bytes an ed25519 private key is, which is the seed rather than the expanded key.
      SEED_SIZE = 32

      class << self
        # Read a key from the file a homeserver keeps it in.
        #
        # @parameter path [String] the file to read.
        # @returns [ServerKey] the key.
        # @raises [InvalidKeyError] if the file does not hold one.
        def load(path)
          self.parse(File.read(path))
        end

        # Read a key from the line a homeserver writes it as.
        #
        # @parameter text [String] the line, e.g. `ed25519 a_pxTp <seed>`.
        # @returns [ServerKey] the key.
        # @raises [InvalidKeyError] if the line does not hold one.
        def parse(text)
          algorithm, key_id, seed = text.strip.split(/\s+/, 3)

          unless algorithm == ALGORITHM
            raise InvalidKeyError, "Unsupported key algorithm #{algorithm.inspect}, expected #{ALGORITHM}!"
          end

          unless key_id and seed
            raise InvalidKeyError, "A signing key is an algorithm, a key ID and a seed!"
          end

          self.new(key_id, Base64.decode64(seed))
        end

        # The unpadded base64 a signature and a key are written as.
        #
        # @parameter bytes [String] the bytes to encode.
        # @returns [String] the encoded bytes.
        def encode(bytes)
          Base64.strict_encode64(bytes).delete("=")
        end
      end

      # @parameter key_id [String] the key's name, e.g. `a_pxTp`.
      # @parameter seed [String] the thirty two bytes the key is derived from.
      # @raises [InvalidKeyError] if the seed is the wrong size.
      def initialize(key_id, seed)
        unless seed.bytesize == SEED_SIZE
          raise InvalidKeyError, "An #{ALGORITHM} seed is #{SEED_SIZE} bytes, not #{seed.bytesize}!"
        end

        @key_id = key_id
        @key = OpenSSL::PKey.new_raw_private_key(ALGORITHM, seed)
      end

      # @attribute [String] the key's name, which is not unique between servers.
      attr :key_id

      # @returns [String] the algorithm this key signs with.
      def algorithm
        ALGORITHM
      end

      # The name a signature is filed under, which is the algorithm and the key ID.
      #
      # @returns [String] the identifier, e.g. `ed25519:a_pxTp`.
      def id
        "#{ALGORITHM}:#{@key_id}"
      end

      # The public half, which is what another server verifies against.
      #
      # @returns [String] the key, as unpadded base64.
      def public_key
        self.class.encode(@key.raw_public_key)
      end

      # Sign an object, which is canonicalised first.
      #
      # @parameter object [Hash] the object to sign.
      # @returns [String] the signature, as unpadded base64.
      def sign(object)
        self.class.encode(@key.sign(nil, E2EE::CanonicalJSON.for_signing(object)))
      end

      # @parameter object [Hash] the object the signature was made over.
      # @parameter signature [String] the signature to check, as unpadded base64.
      # @returns [Boolean] whether it was made by this key.
      def verify(object, signature)
        @key.verify(nil, Base64.decode64(signature), E2EE::CanonicalJSON.for_signing(object))
      rescue OpenSSL::PKey::PKeyError
        false
      end

      def inspect
        "\#<#{self.class} #{self.id}>"
      end
    end
  end
end
