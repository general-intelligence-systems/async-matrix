# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Protocol
  module Matrix
    # Every error the protocol layer raises, defined in one place and nowhere
    # else. There are no aliases back to per-class constant paths: a caller
    # names the full path, `Protocol::Matrix::Errors::MalformedError`, so the
    # class that raises an error and the place the error is defined are never
    # two answers to the same question.
    module Errors
      # THE base error for this gem, in both namespaces: Async::Matrix::Error
      # is a constant pointing here, so `rescue Async::Matrix::Error` catches a
      # format failure and a transport failure alike, and every subclass
      # declared as `class AuthError < Error` inside Async::Matrix resolves to
      # this class.
      #
      # It lives under Protocol:: because an error about bytes should not
      # require there to have been a connection -- but the two namespaces ship
      # in one gem, so there is no dependency direction to defend and no reason
      # for consumers to need two rescues.
      class Error < StandardError
        # The Matrix errcode this maps to, when it maps to one. M_BAD_JSON and
        # friends are spec vocabulary, so a format error is entitled to carry
        # one; most carry none.
        attr_reader :errcode

        # The HTTP status, for the failures that came from one.
        attr_reader :status

        # TWO CALLING CONVENTIONS, deliberately, because this class serves both
        # layers:
        #
        #   Error.new("M_UNKNOWN_TOKEN", "token expired", status: 401)
        #   raise MalformedError, "megolm ciphertext must be a string"
        #
        # The first is how the transport has always raised, and changing it
        # would break every caller. The second is what `raise Klass, "message"`
        # does, which is how a format error reads naturally. A lone argument is
        # the message; two are errcode then message.
        def initialize(errcode = nil, message = nil, status: nil)
          @status = status

          if message.nil?
            @errcode = nil
            super(errcode)
          else
            @errcode = errcode
            super(message)
          end
        end
      end

      # ── CanonicalJson ───────────────────────────────────────────────────────

      class CanonicalJsonError < Error; end

      # ── EncryptedMessage ────────────────────────────────────────────────────

      # A message that does not match the format its own algorithm demands.
      class MalformedError < Error; end

      # An algorithm this library does not implement. NOT fatal to a batch: an
      # unknown algorithm is a message we cannot read, which is the same
      # practical state as a missing key.
      class UnsupportedAlgorithmError < Error; end

      # An Olm event whose ciphertext map has no entry for our identity key.
      class NotAddressedError < Error; end

      # The cryptography itself refused the message: a corrupt ciphertext, a
      # session that cannot read it, a ratchet too far advanced. Wrapped rather
      # than propagated so a caller rescues one protocol error instead of
      # whichever RuntimeError the vodozemac binding happened to raise.
      class DecryptionError < Error; end

      # #payload, #type, #content or #message_index asked for before #decrypt!.
      class NotDecryptedError < Error; end

      # ── KeyBackup ───────────────────────────────────────────────────────────

      class KeyBackupError < Error; end

      # The backed-up session's MAC did not verify: the wrong backup key, or
      # tampered ciphertext.
      class KeyBackupMacError < KeyBackupError; end

      # ── Keys ────────────────────────────────────────────────────────────────

      class KeysError < Error; end

      # ── MessageBatch ────────────────────────────────────────────────────────

      class MessageBatchError < Error; end

      # #read after the batch was drained is fine (nil). This is for a consumer
      # that asks for a second pass over something already consumed.
      class ConsumedError < MessageBatchError; end

      # ── SecretStorage ───────────────────────────────────────────────────────

      class SecretStorageError < Error; end

      # The MAC did not verify: the wrong key, or tampered ciphertext.
      class SecretStorageMacError < SecretStorageError; end

      # The input is neither a recovery key nor usable as a passphrase for this
      # account's key.
      class UnusableKeyError < SecretStorageError; end

      # ── Signing ─────────────────────────────────────────────────────────────

      class SigningError < Error; end

      # No signature from the entity and key we were told to check.
      class MissingSignatureError < SigningError; end

      # ── Schema ──────────────────────────────────────────────────────────────

      # Raised by Event#valid! when data fails schema validation.
      #
      # Produces detailed, human-readable error messages that identify the exact
      # key path and offending value.
      #
      #   Schema validation failed for m.room.member event $abc123:
      #     - content.membership = "invalid" -- must be one of: ["invite", "join", "knock", "leave", "ban"]
      #     - sender is required but missing
      #
      # Carries an errcode, which the base supports: M_BAD_JSON is what a
      # homeserver answers for a payload that fails its schema.
      class ValidationError < Error
        attr_reader :errors, :event_type, :event_id

        # @param errors     [Array<Hash>] raw JSONSchemer error hashes
        # @param event_type [String, nil] Matrix event type (e.g. "m.room.member")
        # @param event_id   [String, nil] Matrix event ID (e.g. "$abc123")
        def initialize(errors, event_type: nil, event_id: nil)
          @errors     = errors
          @event_type = event_type
          @event_id   = event_id
          super("M_BAD_JSON", build_message)
        end

        private

          def build_message
            lines = [header_line]
            @errors.each { |e| lines.concat(Array(format_error(e))) }
            lines.join("\n")
          end

          def header_line
            header = "Schema validation failed"
            if @event_type
              header += " for #{@event_type}"
            end
            if @event_id
              header += " event #{@event_id}"
            end
            header + ":"
          end

          def format_error(error)
            path = pointer_to_dot(error["data_pointer"])
            type = error["type"]
            data = error["data"]

            case type
            when "required"
              format_required(error, path)
            when "string", "integer", "number", "boolean", "array", "object", "null"
              "  - #{path} = #{truncate(data.inspect)} -- expected #{type}, got #{data.class}"
            when "minimum"
              "  - #{path} = #{truncate(data.inspect)} -- must be >= #{error.dig("schema", "minimum")}"
            when "maximum"
              "  - #{path} = #{truncate(data.inspect)} -- must be <= #{error.dig("schema", "maximum")}"
            when "enum"
              allowed = error.dig("schema", "enum")
              "  - #{path} = #{truncate(data.inspect)} -- must be one of: #{truncate(allowed.inspect)}"
            when "pattern"
              pattern = error.dig("schema", "pattern")
              "  - #{path} = #{truncate(data.inspect)} -- does not match pattern: #{pattern}"
            when "format"
              fmt = error.dig("schema", "format")
              "  - #{path} = #{truncate(data.inspect)} -- invalid #{fmt} format"
            when "minLength"
              "  - #{path} = #{truncate(data.inspect)} -- length must be >= #{error.dig("schema", "minLength")}"
            when "maxLength"
              "  - #{path} = #{truncate(data.inspect)} -- length must be <= #{error.dig("schema", "maxLength")}"
            when "minItems"
              "  - #{path} -- array must have >= #{error.dig("schema", "minItems")} items"
            when "maxItems"
              "  - #{path} -- array must have <= #{error.dig("schema", "maxItems")} items"
            when "uniqueItems"
              "  - #{path} -- array items must be unique"
            when "const"
              expected = error.dig("schema", "const")
              "  - #{path} = #{truncate(data.inspect)} -- must be #{truncate(expected.inspect)}"
            when "additionalProperties"
              "  - #{path}: #{error["error"] || "has additional properties that are not allowed"}"
            else
              msg = error["error"] || type
              "  - #{path}: #{msg}"
            end
          end

          def format_required(error, path)
            missing = error.dig("details", "missing_keys") || []
            if missing.empty?
              "  - #{path}: #{error["error"] || "required"}"
            else
              missing.map { |key| "  - #{join_path(path, key)} is required but missing" }
            end
          end

          def pointer_to_dot(pointer)
            if pointer.nil? || pointer.empty?
              "root"
            else
              pointer.delete_prefix("/").gsub("/", ".")
            end
          end

          def join_path(base, key)
            base == "root" ? key.to_s : "#{base}.#{key}"
          end

          def truncate(str, max: 60)
            str.length > max ? "#{str[0...max]}..." : str
          end
      end
    end
  end
end

__END__
  describe "Protocol::Matrix::Errors::Error" do
    it "stores errcode and message" do
      err = Protocol::Matrix::Errors::Error.new("M_UNKNOWN", "something broke")
      err.errcode.should == "M_UNKNOWN"
      err.message.should == "something broke"
    end

    it "stores optional status" do
      err = Protocol::Matrix::Errors::Error.new("M_UNKNOWN", "bad", status: 400)
      err.status.should == 400
    end

    it "defaults status to nil" do
      Protocol::Matrix::Errors::Error.new("M_UNKNOWN", "bad").status.should.be.nil
    end

    it "is a StandardError" do
      Protocol::Matrix::Errors::Error.new("M_UNKNOWN", "bad").should.be.kind_of StandardError
    end
  end

  describe "Protocol::Matrix::Errors::ValidationError" do
    def error_hash(overrides = {})
      {
        "data" => nil,
        "data_pointer" => "",
        "schema" => {},
        "schema_pointer" => "",
        "root_schema" => {},
        "type" => "unknown",
        "error" => "something went wrong"
      }.merge(overrides)
    end

    it "includes event type in header" do
      err = Protocol::Matrix::Errors::ValidationError.new(
        [error_hash],
        event_type: "m.room.message"
      )
      err.message.should.include "Schema validation failed for m.room.message"
    end

    it "includes event ID in header" do
      err = Protocol::Matrix::Errors::ValidationError.new(
        [error_hash],
        event_type: "m.room.member",
        event_id: "$abc123"
      )
      err.message.should.include "m.room.member event $abc123"
    end

    it "formats type mismatch errors" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/content/body",
          "type" => "string",
          "data" => 42
        )
      ])
      err.message.should.include "content.body = 42 -- expected string, got Integer"
    end

    it "formats required errors with missing keys" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/content",
          "type" => "required",
          "details" => {"missing_keys" => ["msgtype", "body"]}
        )
      ])
      err.message.should.include "content.msgtype is required but missing"
      err.message.should.include "content.body is required but missing"
    end

    it "formats enum errors" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/content/membership",
          "type" => "enum",
          "data" => "invalid",
          "schema" => {"enum" => %w[invite join knock leave ban]}
        )
      ])
      err.message.should.include 'content.membership = "invalid" -- must be one of:'
      err.message.should.include "invite"
    end

    it "formats pattern errors" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/state_key",
          "type" => "pattern",
          "data" => "bad",
          "schema" => {"pattern" => "^@"}
        )
      ])
      err.message.should.include 'state_key = "bad" -- does not match pattern: ^@'
    end

    it "formats format errors" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/content/avatar_url",
          "type" => "format",
          "data" => "not-a-uri",
          "schema" => {"format" => "uri"}
        )
      ])
      err.message.should.include "invalid uri format"
    end

    it "truncates long values" do
      err = Protocol::Matrix::Errors::ValidationError.new([
        error_hash(
          "data_pointer" => "/content/body",
          "type" => "integer",
          "data" => "a" * 200
        )
      ])
      err.message.should.include "..."
    end

    it "exposes the raw errors array" do
      raw = [error_hash]
      err = Protocol::Matrix::Errors::ValidationError.new(raw)
      err.errors.should.equal raw
    end
  end
