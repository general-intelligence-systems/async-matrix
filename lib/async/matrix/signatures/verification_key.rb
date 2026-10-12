# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "base64"
require "openssl"

require_relative "../error"

module Async
  module Matrix
    module Signatures
      # The public half of a signing key, which is what checks a signature.
      class VerificationKey
        # The algorithms the specification defines, which is the one NACL implements.
        ALGORITHMS = ["ed25519"].freeze

        class << self
          # @parameter key_id [String] the signing key identifier, e.g. `ed25519:1`.
          # @parameter encoded [String] the key, as unpadded base64.
          # @returns [VerificationKey | nil] the key, or nothing where we cannot check that algorithm.
          # @raises [InvalidKeyError] if the algorithm is ours and the key is not readable.
          def parse(key_id, encoded)
            self.supported?(key_id) ? self.new(self.algorithm_of(key_id), encoded) : nil
          end

          # @parameter key_id [String] the signing key identifier to judge.
          # @returns [Boolean] whether we understand the algorithm it names.
          def supported?(key_id)
            ALGORITHMS.include?(self.algorithm_of(key_id))
          end

          # The signing algorithm, which is the part of the identifier before the key identifier.
          #
          # @parameter key_id [String] the signing key identifier to read.
          # @returns [String] the algorithm it names.
          def algorithm_of(key_id)
            key_id.to_s.split(":", 2).first.to_s
          end

          # The padding the specification leaves off, which `strict_decode64` wants back.
          #
          # @parameter encoded [String] the unpadded base64 to read.
          # @returns [String] the bytes it holds.
          # @raises [ArgumentError] if it is not base64.
          def decode(encoded)
            ::Base64.strict_decode64(encoded + ("=" * ((4 - (encoded.bytesize % 4)) % 4)))
          end
        end

        # @parameter algorithm [String] the signing algorithm, e.g. `ed25519`.
        # @parameter encoded [String] the key, as unpadded base64.
        # @raises [InvalidKeyError] if the key is not readable.
        def initialize(algorithm, encoded)
          @algorithm = algorithm
          @encoded = encoded
          @key = OpenSSL::PKey.new_raw_public_key(algorithm, self.class.decode(encoded))
        rescue ArgumentError, OpenSSL::PKey::PKeyError => error
          raise InvalidKeyError, "#{encoded.inspect} is not an #{algorithm} key: #{error.message}"
        end

        # @attribute [String] the signing algorithm, e.g. `ed25519`.
        attr :algorithm

        # @attribute [String] the key, as unpadded base64.
        attr :encoded

        # @parameter bytes [String] the canonical form which was signed.
        # @parameter signature [String] the signature bytes.
        # @returns [Boolean] whether this key made it.
        def verify(bytes, signature)
          @key.verify(nil, signature, bytes)
        rescue OpenSSL::PKey::PKeyError
          false
        end

        def inspect
          "\#<#{self.class} #{@algorithm}>"
        end
      end
    end
  end
end
