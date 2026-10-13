# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json_schemer"
require "yaml"

require_relative "error"

module Async
  module Matrix
    # Raised where a document does not answer what the specification asks of it.
    class InvalidDocumentError < Error
      # @parameter operation [String] the operation ID, e.g. `login`.
      # @parameter version [String] the specification version the document was read against.
      # @parameter errors [Array(String)] what was wrong with it.
      def initialize(operation, version, errors)
        super("#{operation} does not answer what #{version} asks of it: #{errors.join("; ")}!")

        @operation = operation
        @version = version
        @errors = errors
      end

      # @attribute [String] the operation ID.
      attr :operation

      # @attribute [String] the specification version.
      attr :version

      # @attribute [Array(String)] what was wrong with the document.
      attr :errors
    end

    # Raised where a path names more than one operation, so that nothing can say which was called.
    class AmbiguousPathError < Error
      # @parameter path [String] the path which was asked about.
      # @parameter operations [Array(String)] the operation IDs which share it.
      def initialize(path, operations)
        super("#{path} is the path of #{operations.join(", ")}: name the one to check against!")

        @path = path
        @operations = operations
      end

      # @attribute [String] the path which was asked about.
      attr :path

      # @attribute [Array(String)] the operation IDs which share it.
      attr :operations
    end

    # What the specification asks of one concept's documents, at one version.
    class Schema
      # The schemas this gem ships are generated from the specification: each names its operations, and each operation the fields of its request and of every response it describes.
      #
      # This reads one and answers a schema a document can be checked against, so that `required` is enforced rather than merely recorded.

      # Where the generated schemas are, which ship with the gem.
      ROOT = File.expand_path("abstract", __dir__)

      # The keys the generated schemas use to describe a field, as against the names of the fields themselves.
      #
      # A field named `pattern` or `format` is a field, not a keyword: a descriptor is what carries a `type`.
      STRUCTURE = ["type", "required", "description", "fields", "enum", "keyed_by"].freeze

      class << self
        # The schema for one concept at one version, built once and cached.
        #
        # @parameter api [String] the API, e.g. `client_server`, or `events`.
        # @parameter concept [String] the concept, e.g. `session`.
        # @parameter version [String] the specification version, e.g. `v1.19`.
        # @returns [Schema | nil] the schema, or nil where the version describes no such concept.
        def for(api, concept, version)
          @schemas ||= {}

          if @schemas.key?([api, concept, version])
            @schemas[[api, concept, version]]
          else
            @schemas[[api, concept, version]] = self.load(api, concept, version)
          end
        end

        # Every concept the given API describes at the given version.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @parameter version [String] the specification version.
        # @returns [Array(String)] the concepts, named as a Ruby file would be.
        def concepts(api, version)
          Dir.glob(File.join(self.directory(api), "*-#{version}.yaml")).filter_map do |path|
            unless path.end_with?(".deltas.yaml")
              File.basename(path).delete_suffix("-#{version}.yaml").tr("-", "_")
            end
          end.sort
        end

        # The operation a path names, which is how a document says what to check itself against.
        #
        # The operation a path names, where only one method answers it.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @parameter version [String] the specification version.
        # @parameter path [String] the path the request was made against.
        # @parameter method [String | nil] the HTTP method, where the path names more than one operation.
        # @returns [Array(Schema, String)] the schema and the operation ID, or nil where no operation has that path.
        def operation_for(api, version, path, method: nil)
          # A path is shared by every method which answers it, so the `GET` and the `PUT` of one path are two operations.
          matched = self.index(api, version).select{|pattern, _| pattern.match?(path)}.values.flatten(1)

          found = matched.select do |concept, operation|
            method.nil? || self.for(api, concept, version).operations.dig(operation, "method") == method.to_s.upcase
          end

          case found.uniq
          in [[String => concept, String => operation]]
            [self.for(api, concept, version), operation]
          in [[String, String], *] => several
            raise AmbiguousPathError.new(path, several.map(&:last))
          else
            nil
          end
        end

        # Every operation of an API at a version, by the pattern its path makes.
        #
        # @parameter api [String] the API.
        # @parameter version [String] the specification version.
        # @returns [Hash] the concepts and operation IDs, by pattern.
        def index(api, version)
          @indexes ||= {}
          @indexes[[api, version]] ||= self.concepts(api, version).each_with_object({}) do |concept, index|
            self.for(api, concept, version).operations.each do |operation, described|
              if described["path"]
                # Every method of a path is its own operation, so one pattern may name several.
                (index[self.pattern(described["path"])] ||= []) << [concept, operation]
              end
            end
          end
        end

        # What a path template matches, which is one segment per parameter it names.
        #
        # A state key may be empty, so a segment is allowed to be: `/state/m.room.name/` names one.
        #
        # @parameter template [String] the path as the specification writes it, e.g. `/rooms/{roomId}/state`.
        # @returns [Regexp] what that path matches.
        def pattern(template)
          literal = template.split(/(\{[^}]+\})/).map do |part|
            if part.start_with?("{")
              "[^/]*"
            else
              Regexp.escape(part)
            end
          end

          /\A#{literal.join}\z/
        end

        # Where one API's schemas are.
        #
        # @parameter api [String] the API, e.g. `client_server`, or `events`.
        # @returns [String] the directory.
        def directory(api)
          case api.to_s
          in "events"
            File.join(ROOT, "events", "schemas")
          in String => named
            File.join(ROOT, "api", named, "schemas")
          end
        end

        private

        # @parameter api [String] the API.
        # @parameter concept [String] the concept.
        # @parameter version [String] the specification version.
        # @returns [Schema | nil] the schema, or nil where there is no such file.
        def load(api, concept, version)
          # The schema keeps the specification's own name, which may be hyphenated where a Ruby file cannot be.
          path = [concept.to_s, concept.to_s.tr("_", "-")].uniq.lazy.map do |name|
            File.join(self.directory(api), "#{name}-#{version}.yaml")
          end.find{|candidate| File.exist?(candidate)}

          if path
            self.new(YAML.safe_load_file(path), version: version)
          else
            nil
          end
        end
      end

      # @parameter document [Hash] the schema as it was generated.
      # @parameter version [String] the specification version it describes.
      def initialize(document, version:)
        @document = document
        @version = version
        @validators = {}
      end

      # @attribute [String] the specification version this describes.
      attr :version

      # @returns [Hash] the operations this concept has, by ID.
      def operations
        @document["operations"] || {}
      end

      # @returns [Hash] the events this schema describes, by type, where it describes events.
      def events
        @document["events"] || {}
      end

      # Whether a document answers what an operation's response asks of it.
      #
      # @parameter operation [String] the operation ID, e.g. `login`.
      # @parameter value [Hash] the document the server answered with.
      # @parameter status [Integer | String] which response it is, which is the 200 unless said otherwise.
      # @returns [Array(String)] what was wrong with it, which is empty where nothing was.
      def errors_in_response(operation, value, status: 200)
        self.errors_against(self.response(operation, status: status), value)
      end

      # Whether a document answers what an operation's request asks of it.
      #
      # @parameter operation [String] the operation ID.
      # @parameter value [Hash] the document to send.
      # @returns [Array(String)] what was wrong with it, which is empty where nothing was.
      def errors_in_request(operation, value)
        self.errors_against(self.request(operation), value)
      end

      # The same as {#errors_in_response}, raising rather than answering.
      #
      # @parameter operation [String] the operation ID.
      # @parameter value [Hash] the document the server answered with.
      # @parameter status [Integer | String] which response it is.
      # @returns [Hash] the document, so that this can be used where it is read.
      def validate_response(operation, value, status: 200)
        errors = self.errors_in_response(operation, value, status: status)

        unless errors.empty?
          raise InvalidDocumentError.new(operation, @version, errors)
        end

        value
      end

      # The same as {#errors_in_request}, raising rather than answering.
      #
      # @parameter operation [String] the operation ID.
      # @parameter value [Hash] the document to send.
      # @returns [Hash] the document, so that this can be used where it is sent.
      def validate_request(operation, value)
        errors = self.errors_in_request(operation, value)

        unless errors.empty?
          raise InvalidDocumentError.new(operation, @version, errors)
        end

        value
      end

      # The fields an operation's response always carries, which is what `required` records.
      #
      # @parameter operation [String] the operation ID.
      # @parameter status [Integer | String] which response it is.
      # @returns [Array(Symbol)] the names, which is empty where the response asks for none.
      def required_in_response(operation, status: 200)
        self.required_of(self.fields_of_response(operation, status: status))
      end

      # The fields an operation's request always carries.
      #
      # @parameter operation [String] the operation ID.
      # @returns [Array(Symbol)] the names.
      def required_in_request(operation)
        self.required_of(self.fields_of_request(operation))
      end

      # One response as a JSON Schema document.
      #
      # @parameter operation [String] the operation ID.
      # @parameter status [Integer | String] which response it is.
      # @returns [Hash | nil] the schema, or nil where the version describes no such response.
      def response(operation, status: 200)
        self.object_schema(self.fields_of_response(operation, status: status))
      end

      # One request as a JSON Schema document.
      #
      # @parameter operation [String] the operation ID.
      # @returns [Hash | nil] the schema, or nil where the operation sends no body.
      def request(operation)
        self.object_schema(self.fields_of_request(operation))
      end

      def inspect
        "\#<#{self.class} #{@version} #{self.operations.keys.size} operations>"
      end

      private

      # @parameter operation [String] the operation ID.
      # @parameter status [Integer | String] which response it is.
      # @returns [Hash | nil] the field map, or nil where there is no such response.
      def fields_of_response(operation, status: 200)
        (self.operations.dig(operation, "responses") || {})[status.to_s]
      end

      # @parameter operation [String] the operation ID.
      # @returns [Hash | nil] the field map, or nil where the operation sends no body.
      def fields_of_request(operation)
        self.operations.dig(operation, "request")
      end

      # @parameter fields [Hash | nil] the field map.
      # @returns [Array(Symbol)] the names the map requires.
      def required_of(fields)
        case fields
        in Hash => named
          named.select{|_, field| self.descriptor?(field) && field["required"]}.keys.map(&:to_sym)
        else
          []
        end
      end

      # Check a document against a schema, which is nothing to check where the version describes none.
      #
      # @parameter schema [Hash | nil] the JSON Schema document.
      # @parameter value [Hash] the document to check.
      # @returns [Array(String)] what was wrong with it.
      def errors_against(schema, value)
        case schema
        in Hash => against
          self.validator(against).validate(self.stringify(value)).map do |error|
            self.describe(error)
          end
        else
          []
        end
      end

      # @parameter schema [Hash] the JSON Schema document.
      # @returns [JSONSchemer::Schema] the validator, built once per schema.
      def validator(schema)
        @validators[schema] ||= JSONSchemer.schema(schema)
      end

      # What json_schemer reported, as a line a person can read.
      #
      # @parameter error [Hash] one of json_schemer's errors.
      # @returns [String] the description.
      def describe(error)
        case error["data_pointer"]
        in ""
          where = "the document"
        in String => pointer
          where = pointer
        end

        case error["type"]
        in "required"
          "#{where} is missing #{(error.dig("details", "missing_keys") || []).join(", ")}"
        in String => type
          "#{where} is not #{type}"
        end
      end

      # A field map as a JSON Schema object, which is open rather than closed.
      #
      # @parameter fields [Hash | nil] the field map.
      # @returns [Hash | nil] the schema, or nil where there is no map to build one from.
      def object_schema(fields)
        case fields
        in Hash => named
          # The specification lets a server send fields a version does not describe, and a client which refused them would break on the next version rather than on a fault.
          properties = named.reject{|name, _| name == "(*)"}
          wildcard = named["(*)"]

          {"type" => "object"}.tap do |schema|
            schema["properties"] = properties.to_h{|name, field| [name, self.field_schema(field)]}

            required = self.required_of(named).map(&:to_s)

            unless required.empty?
              schema["required"] = required
            end

            if wildcard
              schema["additionalProperties"] = self.field_schema(wildcard)
            end
          end
        else
          nil
        end
      end

      # One field as a JSON Schema document.
      #
      # @parameter field [Hash] the descriptor.
      # @returns [Hash] the schema.
      def field_schema(field)
        case self.descriptor?(field) && field["type"]
        in "object"
          self.object_schema(field["fields"]) || {"type" => "object"}
        in "array"
          {"type" => "array"}.tap do |schema|
            items = self.items_schema(field["fields"])

            if items
              schema["items"] = items
            end
          end
        in String => type
          {"type" => type}.tap do |schema|
            if field["enum"]
              schema["enum"] = field["enum"]
            end
          end
        else
          {}
        end
      end

      # What an array's members are, which the schemas write as a map in a list of one.
      #
      # @parameter fields [Array | Hash | nil] what the descriptor said its members are.
      # @returns [Hash | nil] the schema for one member, or nil where the members are unconstrained.
      def items_schema(fields)
        case fields
        in [Hash => first, *]
          self.object_schema(first)
        in Hash => named
          self.object_schema(named)
        else
          nil
        end
      end

      # Whether this is a field's descriptor rather than a field map, which is what carrying a type says.
      #
      # @parameter field [Object] what the schema held.
      # @returns [Boolean] whether it describes one field.
      def descriptor?(field)
        field.is_a?(Hash) && field["type"].is_a?(String)
      end

      # A document as json_schemer reads it, which is names as strings.
      #
      # @parameter value [Object] the document.
      # @returns [Object] the same, with every name a string.
      def stringify(value)
        # The library answers symbol keys, because a Matrix document is read by pattern matching and a pattern names a symbol.
        case value
        in Hash => hash
          hash.to_h{|name, held| [name.to_s, self.stringify(held)]}
        in Array => array
          array.map{|held| self.stringify(held)}
        else
          value
        end
      end
    end
  end
end
