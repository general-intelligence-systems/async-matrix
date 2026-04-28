# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../error"

module Async
	module Matrix
		module Schema
			# Raised by Event#valid! when data fails schema validation.
			#
			# Produces detailed, human-readable error messages that identify the exact
			# key path and offending value.
			#
			#   Schema validation failed for m.room.member event $abc123:
			#     - content.membership = "invalid" -- must be one of: ["invite", "join", "knock", "leave", "ban"]
			#     - sender is required but missing
			#
			class ValidationError < Async::Matrix::Error
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
						header += " for #{@event_type}" if @event_type
						header += " event #{@event_id}" if @event_id
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
						return "root" if pointer.nil? || pointer.empty?
						pointer.delete_prefix("/").gsub("/", ".")
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

test do
	describe "Async::Matrix::Schema::ValidationError" do
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
			err = Async::Matrix::Schema::ValidationError.new(
				[error_hash],
				event_type: "m.room.message"
			)
			err.message.should.include "Schema validation failed for m.room.message"
		end

		it "includes event ID in header" do
			err = Async::Matrix::Schema::ValidationError.new(
				[error_hash],
				event_type: "m.room.member",
				event_id: "$abc123"
			)
			err.message.should.include "m.room.member event $abc123"
		end

		it "formats type mismatch errors" do
			err = Async::Matrix::Schema::ValidationError.new([
				error_hash(
					"data_pointer" => "/content/body",
					"type" => "string",
					"data" => 42
				)
			])
			err.message.should.include "content.body = 42 -- expected string, got Integer"
		end

		it "formats required errors with missing keys" do
			err = Async::Matrix::Schema::ValidationError.new([
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
			err = Async::Matrix::Schema::ValidationError.new([
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
			err = Async::Matrix::Schema::ValidationError.new([
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
			err = Async::Matrix::Schema::ValidationError.new([
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
			err = Async::Matrix::Schema::ValidationError.new([
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
			err = Async::Matrix::Schema::ValidationError.new(raw)
			err.errors.should.equal raw
		end
	end
end
