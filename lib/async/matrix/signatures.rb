# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "error"
require_relative "e2ee/canonical_json"
require_relative "signatures/keyring"
require_relative "signatures/verification_key"

module Async
  module Matrix
    # Raised when an object does not carry the signature it was checked for.
    #
    # The reason is the step of the appendices' algorithm which failed.
    class SignatureError < Error
      # @parameter reason [Symbol] which step failed.
      # @parameter message [String] what failed, in words.
      # @parameter entity [String] whose signature was being checked.
      # @parameter key_id [String | nil] the signing key identifier, where one was reached.
      def initialize(reason, message, entity:, key_id: nil)
        super(message)

        @reason = reason
        @entity = entity
        @key_id = key_id
      end

      # @attribute [Symbol] which step failed, e.g. `:no_entity` or `:mismatch`.
      attr :reason

      # @attribute [String] whose signature was being checked.
      attr :entity

      # @attribute [String | nil] the signing key identifier, where one was reached.
      attr :key_id
    end

    # The making and checking of signatures.
    module Signatures
      # The member a signature is filed under, which the signature never covers.
      MEMBER = :signatures

      class << self
        # Sign an object, filing the signature beside any already there.
        #
        # The object is not changed: intermediate entities add their own signature to what they were given.
        #
        # @parameter object [Hash] the object to sign.
        # @parameter key [ServerKey] the key to sign with.
        # @parameter as [String] the entity the signature is made by.
        # @returns [Hash] a copy of the object, carrying the signature.
        def sign(object, key:, as:)
          signatures = self.deep_copy(self.signatures(object))
          entity = signatures[as.to_s] ||= {}
          entity[key.id] = key.sign(object)

          object.merge(self.member_of(object) => signatures)
        end

        # The algorithm the appendices give for checking a signature.
        #
        # Every signature we hold a key for must verify, and at least one must have been checked.
        #
        # @parameter object [Hash] the object the signature is over.
        # @parameter entity [String] whose signature to check.
        # @parameter keyring [Keyring] where to look a verification key up.
        # @returns [Array(String)] the signing key identifiers which verified it.
        # @raises [SignatureError] at whichever step fails.
        def verify!(object, entity:, keyring:)
          signatures = self.signatures_of(object, entity)
          bytes = E2EE::CanonicalJSON.for_signing(object)

          self.understood(signatures, entity).filter_map do |key_id, signature|
            verification_key = keyring.verification_key(entity, key_id)

            verification_key && self.check(bytes, signature, key_id, verification_key, entity)
          end.tap do |checked|
            if checked.empty?
              raise SignatureError.new(:no_verification_key, "There is no verification key for #{entity.inspect}!", entity: entity)
            end
          end
        end

        # @parameter object [Hash] the object the signature is over.
        # @parameter entity [String] whose signature to check.
        # @parameter keyring [Keyring] where to look a verification key up.
        # @returns [Boolean] whether the entity signed it.
        def verify?(object, entity:, keyring:)
          self.verify!(object, entity: entity, keyring: keyring)

          true
        rescue SignatureError
          false
        end

        # @parameter object [Hash] the object to read.
        # @returns [Hash] the signatures it carries, by entity and signing key identifier.
        def signatures(object)
          object[MEMBER] || object[MEMBER.to_s] || {}
        end

        # The first step: the entry for the entity, which must be there.
        #
        # @parameter object [Hash] the object to read.
        # @parameter entity [String] whose signatures to find.
        # @returns [Hash] their signatures, by signing key identifier.
        # @raises [SignatureError] if they signed nothing.
        def signatures_of(object, entity)
          signatures = self.signatures(object)
          mine = signatures[entity.to_s] || signatures[entity.to_s.to_sym]

          unless mine and !mine.empty?
            raise SignatureError.new(:no_entity, "There are no signatures from #{entity.inspect}!", entity: entity)
          end

          mine
        end

        # The second step: the identifiers whose algorithm we understand, of which there must be one.
        #
        # @parameter signatures [Hash] the entity's signatures, by signing key identifier.
        # @parameter entity [String] whose signatures they are.
        # @returns [Hash] those we could check, by signing key identifier.
        # @raises [SignatureError] if we understand none of them.
        def understood(signatures, entity)
          signatures.to_h{|key_id, signature| [key_id.to_s, signature]}.select do |key_id, _|
            VerificationKey.supported?(key_id)
          end.tap do |known|
            if known.empty?
              raise SignatureError.new(:no_known_algorithm, "No signature from #{entity.inspect} uses an algorithm we know!", entity: entity)
            end
          end
        end

        # The fourth step and the last, which are the base64 and the signature itself.
        #
        # @parameter bytes [String] the canonical form the signature is over.
        # @parameter signature [String] the signature, as unpadded base64.
        # @parameter key_id [String] the signing key identifier it was made with.
        # @parameter verification_key [VerificationKey] the key to check it against.
        # @parameter entity [String] whose signature it is.
        # @returns [String] the signing key identifier, where it verified.
        # @raises [SignatureError] if the signature is not base64, or does not match.
        def check(bytes, signature, key_id, verification_key, entity)
          decoded = self.decode(signature, key_id, entity)

          unless verification_key.verify(bytes, decoded)
            raise SignatureError.new(:mismatch, "The signature from #{entity.inspect} under #{key_id.inspect} does not match!", entity: entity, key_id: key_id)
          end

          key_id
        end

        # The fourth step: the signature is base64, and nothing can be checked until it is read.
        #
        # @parameter signature [String] the signature, as unpadded base64.
        # @parameter key_id [String] the signing key identifier it was made with.
        # @parameter entity [String] whose signature it is.
        # @returns [String] the signature bytes.
        # @raises [SignatureError] if it is not base64.
        def decode(signature, key_id, entity)
          VerificationKey.decode(signature.to_s)
        rescue ArgumentError
          raise SignatureError.new(:malformed_signature, "The signature from #{entity.inspect} under #{key_id.inspect} is not base64!", entity: entity, key_id: key_id)
        end

        # @parameter object [Hash] the object to read.
        # @returns [Symbol | String] the key its signatures are filed under, however it names them.
        def member_of(object)
          object.key?(MEMBER.to_s) ? MEMBER.to_s : MEMBER
        end

        # @parameter signatures [Hash] the signatures to copy.
        # @returns [Hash] a copy, whose entities can be added to without changing the original.
        def deep_copy(signatures)
          signatures.to_h do |entity, keys|
            [entity.to_s, keys.to_h{|key_id, signature| [key_id.to_s, signature]}]
          end
        end
      end
    end
  end
end
