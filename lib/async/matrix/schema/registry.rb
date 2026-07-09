# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "yaml"
require "json"
require "json_schemer"
require "pathname"

module Async
	module Matrix
		module Schema
			# Loads and indexes Matrix event schemas from the official matrix-org/matrix-spec
			# YAML files bundled in data/matrix-spec/event-schemas/schema/.
			#
			# Schemas are loaded lazily on first access and cached for the lifetime of the
			# process. Each schema is a JSONSchemer::Schema instance that resolves relative
			# $ref paths (e.g. core-event-schema/room_event.yaml) via a file-based resolver.
			#
			#   registry = Async::Matrix::Schema::Registry.instance
			#   registry["m.room.message"]                         # => JSONSchemer::Schema
			#   registry.variant("m.room.message", "m.text")       # => JSONSchemer::Schema
			#   registry.event_types                                # => ["m.accepted_terms", ...]
			#
			class Registry
				# Custom format validators for Matrix-specific format hints.
				MATRIX_FORMATS = {
					"mx-user-id"        => ->(value, _schema) { value.is_a?(String) && value.match?(/\A@[^:]+:.+\z/) },
					"mx-room-id"        => ->(value, _schema) { value.is_a?(String) && value.match?(/\A![^:]+:.+\z/) },
					"mx-event-id"       => ->(value, _schema) { value.is_a?(String) && value.match?(/\A\$/) },
					"mx-room-alias"     => ->(value, _schema) { value.is_a?(String) && value.match?(/\A#[^:]+:.+\z/) },
					"mx-server-name"    => ->(value, _schema) { value.is_a?(String) && !value.empty? },
					"mx-unpadded-base64" => ->(value, _schema) { value.is_a?(String) && value.match?(/\A[A-Za-z0-9+\/]*\z/) },
				}.freeze

				GEM_ROOT = File.expand_path("../../../..", __dir__)
				SCHEMA_DIR = File.join(GEM_ROOT, "data", "matrix-spec", "event-schemas", "schema")

				@instance = nil

				class << self
					# Returns the singleton Registry instance, creating it on first access.
					def instance
						@instance ||= new
					end

					# Reset the singleton (useful for testing).
					def reset!
						@instance = nil
					end
				end

				def initialize
					@schemas = {}
					@variants = {}
					@loaded = false
				end

				# Look up a schema by Matrix event type (e.g. "m.room.message").
				# Returns a JSONSchemer::Schema or nil if no schema exists for that type.
				def [](event_type)
					load_schemas! unless @loaded
					@schemas[event_type]
				end

				# Look up a variant schema (e.g. variant("m.room.message", "m.text")).
				# Returns a JSONSchemer::Schema or nil.
				def variant(event_type, subtype)
					load_schemas! unless @loaded
					@variants[[event_type, subtype]]
				end

				# All known base event types (excludes variant subtypes).
				# @return [Array<String>] sorted event type strings
				def event_types
					load_schemas! unless @loaded
					@schemas.keys.sort
				end

				# All known variant keys as [event_type, subtype] pairs.
				# @return [Array<Array(String, String)>]
				def variant_types
					load_schemas! unless @loaded
					@variants.keys.sort
				end

				# Total number of schemas loaded (base + variants).
				def size
					load_schemas! unless @loaded
					@schemas.size + @variants.size
				end

				# Validate an event hash against its schema.
				# Returns an array of error hashes (empty if valid).
				# If no schema exists for the event type, returns empty (lenient).
				def validate(event_hash)
					event_type = event_hash["type"]
					return [] unless event_type

					base = self[event_type]
					return [] unless base

					errors = base.validate(event_hash).to_a

					# Also validate against variant if applicable
					variant_key = detect_variant_key(event_type, event_hash)
					if variant_key
						variant_schema = variant(event_type, variant_key)
						if variant_schema
							errors.concat(variant_schema.validate(event_hash).to_a)
						end
					end

					errors
				end

				# Boolean validation.
				def valid?(event_hash)
					validate(event_hash).empty?
				end

				# Content properties defined by the schema for a given event type.
				# Returns an array of property name strings, or empty array if unknown.
				def content_properties(event_type)
					schema = self[event_type]
					return [] unless schema

					extract_content_properties(schema.value)
				end

				private

					# Ref resolver that loads YAML/JSON files from disk.
					# json_schemer calls this with a URI for each $ref it encounters.
					def ref_resolver
						@ref_resolver ||= proc do |uri|
							path = uri.path
							if path && File.exist?(path)
								content = File.read(path)
								if path.end_with?(".yaml", ".yml")
									YAML.safe_load(content, permitted_classes: [Symbol])
								else
									JSON.parse(content)
								end
							else
								raise JSONSchemer::UnknownRef, uri.to_s
							end
						end
					end

					# Build a JSONSchemer::Schema from a parsed YAML hash, anchored at the
					# given file path so relative $ref paths resolve correctly.
					def build_schemer(parsed, file_path)
						uri = URI("file://#{File.expand_path(file_path)}")
						JSONSchemer.schema(
							parsed,
							base_uri: uri,
							ref_resolver: ref_resolver,
							insert_property_defaults: false,
							formats: MATRIX_FORMATS
						)
					end

					# Scan the schema directory and load all event schemas.
					def load_schemas!
						return if @loaded

						Dir.glob(File.join(SCHEMA_DIR, "*.yaml")).each do |path|
							load_schema_file(path)
						end

						# Also load JSON schema files (a few older schemas are JSON)
						Dir.glob(File.join(SCHEMA_DIR, "*.json")).each do |path|
							load_schema_file(path)
						end

						@loaded = true
					end

					def load_schema_file(path)
						filename = File.basename(path, File.extname(path))
						content = File.read(path)
						parsed = path.end_with?(".json") ? JSON.parse(content) : YAML.safe_load(content, permitted_classes: [Symbol])

						schemer = build_schemer(parsed, path)

						# Detect event type from schema: properties.type.enum[0]
						declared_type = parsed.dig("properties", "type", "enum")&.first

						if filename.include?("$")
							# Variant schema: "m.room.message$m.text" -> base="m.room.message", sub="m.text"
							parts = filename.split("$", 2)
							base_type = declared_type || parts[0]
							subtype = parts[1]
							@variants[[base_type, subtype]] = schemer
						elsif declared_type
							@schemas[declared_type] = schemer
						else
							# Schemas without a type enum (like core-event-schema/) are skipped
							# from the index -- they're only used as $ref targets.
						end
					rescue => e
						# Don't let a single broken schema prevent loading the rest
						warn "async-matrix: failed to load schema #{path}: #{e.message}"
					end

					# Detect the variant subtype key from an event hash.
					# For m.room.message, the variant is the msgtype.
					# For m.room.encrypted, the variant is the algorithm.
					# For m.key.verification.start, the variant is the method.
					def detect_variant_key(event_type, event_hash)
						content = event_hash["content"]
						return nil unless content.is_a?(Hash)

						case event_type
						when "m.room.message"
							content["msgtype"]
						when "m.room.encrypted"
							content["algorithm"]
						when "m.key.verification.start"
							content["method"]
						end
					end

					# Extract content property names from a schema's parsed YAML.
					def extract_content_properties(schema_hash)
						props = schema_hash.dig("properties", "content", "properties")
						return [] unless props.is_a?(Hash)
						props.keys
					end
			end
		end
	end
end

__END__
	describe "Async::Matrix::Schema::Registry" do
		it "loads schemas from disk" do
			Async::Matrix::Schema::Registry.instance.size.should.be > 0
		end

		it "has known event types" do
			types = Async::Matrix::Schema::Registry.instance.event_types
			types.should.include "m.room.message"
			types.should.include "m.room.member"
			types.should.include "m.room.create"
			types.should.include "m.reaction"
		end

		it "returns a JSONSchemer::Schema for a known type" do
			schema = Async::Matrix::Schema::Registry.instance["m.room.message"]
			schema.should.not.be.nil
			schema.should.be.kind_of JSONSchemer::Schema
		end

		it "returns nil for an unknown type" do
			Async::Matrix::Schema::Registry.instance["m.fake.event"].should.be.nil
		end

		it "has variant schemas" do
			Async::Matrix::Schema::Registry.instance.variant_types.should.not.be.empty
		end

		it "resolves variant schemas" do
			schema = Async::Matrix::Schema::Registry.instance.variant("m.room.message", "m.text")
			schema.should.not.be.nil
			schema.should.be.kind_of JSONSchemer::Schema
		end

		it "validates a correct m.room.message event" do
			event = {
				"type" => "m.room.message",
				"content" => {"msgtype" => "m.text", "body" => "hello"},
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.valid?(event).should == true
		end

		it "rejects m.room.message missing body" do
			event = {
				"type" => "m.room.message",
				"content" => {"msgtype" => "m.text"},
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.valid?(event).should == false
		end

		it "is lenient with unknown event types" do
			event = {
				"type" => "m.room.other",
				"content" => {"msgtype" => "m.text", "body" => "hi"},
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.valid?(event).should == true
		end

		it "validates m.room.member with correct membership" do
			event = {
				"type" => "m.room.member",
				"content" => {"membership" => "join"},
				"state_key" => "@alice:example.org",
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.valid?(event).should == true
		end

		it "rejects m.room.member with invalid membership" do
			event = {
				"type" => "m.room.member",
				"content" => {"membership" => "invalid_state"},
				"state_key" => "@alice:example.org",
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.valid?(event).should == false
		end

		it "returns content properties for known types" do
			props = Async::Matrix::Schema::Registry.instance.content_properties("m.room.message")
			props.should.include "msgtype"
			props.should.include "body"
		end

		it "returns empty content properties for unknown types" do
			Async::Matrix::Schema::Registry.instance.content_properties("m.fake.type").should == []
		end

		it "performs variant validation for m.room.message with msgtype" do
			event = {
				"type" => "m.room.message",
				"content" => {"msgtype" => "m.text", "body" => "hello"},
				"event_id" => "$abc123",
				"sender" => "@alice:example.org",
				"origin_server_ts" => 1234567890,
				"room_id" => "!room:example.org"
			}
			Async::Matrix::Schema::Registry.instance.validate(event).should == []
		end
	end
