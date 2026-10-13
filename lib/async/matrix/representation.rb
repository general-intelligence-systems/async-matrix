# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/representation"

require_relative "operations"
require_relative "redacted"
require_relative "schema"
require_relative "wrapper/json"

module Async
  module Matrix
    # The base representation for all Matrix responses.
    class Representation < Async::REST::Representation[Wrapper::JSON]
      include Redacted

      # The specification version this document was read against, which a versioned class answers for itself.
      #
      # @returns [String | nil] the version, or nil where this document came from no version's class.
      def version
        nil
      end

      # What the specification asks of this document, which anybody may ask.
      #
      # @parameter operation [String | nil] the operation ID, where the path names more than one.
      # @parameter method [String | nil] the HTTP method, which says which operation a shared path is.
      # @parameter status [Integer] which of the operation's responses this is.
      # @returns [Array(String)] what was wrong with it, which is empty where nothing was.
      def errors(operation: nil, method: nil, status: 200)
        # A version which describes neither the path nor the operation asks nothing of it.
        case self.described(operation: operation, method: method)
        in [Schema => schema, String => named]
          schema.errors_in_response(named, self.value, status: status)
        else
          []
        end
      end

      # @parameter operation [String | nil] the operation ID.
      # @parameter method [String | nil] the HTTP method.
      # @parameter status [Integer] which response this is.
      # @returns [Boolean] whether the document answers what the specification asks.
      def valid?(operation: nil, method: nil, status: 200)
        self.errors(operation: operation, method: method, status: status).empty?
      end

      # The same as {#errors}, raising rather than answering.
      #
      # @parameter operation [String | nil] the operation ID.
      # @parameter method [String | nil] the HTTP method.
      # @parameter status [Integer] which response this is.
      # @returns [Representation] this document, so that it can be used where it is read.
      def validate(operation: nil, method: nil, status: 200)
        found = self.errors(operation: operation, method: method, status: status)

        unless found.empty?
          raise InvalidDocumentError.new(operation || self.resource.path, self.version, found)
        end

        self
      end

      # What a pattern reads, which is the document the homeserver answered with.
      #
      # @parameter keys [Array(Symbol) | nil] the names a pattern asked for.
      # @returns [Hash] the value.
      def deconstruct_keys(keys)
        # So a response is matched where it arrives, rather than having to be taken apart first. `[]` cannot do this, because `async-rest` already uses it to derive a sub-resource.
        case self.value
        in Hash => value
          value
        else
          {}
        end
      end

      private

      # Which operation this document is a response to, which the path says unless two of them share it.
      #
      # @parameter operation [String | nil] the operation ID, where it was given.
      # @parameter method [String | nil] the HTTP method.
      # @returns [Array(Schema, String) | nil] the schema and the operation ID.
      def described(operation: nil, method: nil)
        version = self.version

        if version
          case operation
          in String => named
            self.schema_with(named, version)&.then{|schema| [schema, named]}
          in nil
            Schema.operation_for(self.api_name, version, self.resource.path, method: method)
          end
        else
          nil
        end
      end

      # The concept whose schema holds the named operation, since a name says nothing about where it lives.
      #
      # @parameter operation [String] the operation ID.
      # @parameter version [String] the specification version.
      # @returns [Schema | nil] the schema, or nil where this version names no such operation.
      def schema_with(operation, version)
        api = self.api_name

        Schema.concepts(api, version).lazy.filter_map do |concept|
          schema = Schema.for(api, concept, version)

          if schema.operations.key?(operation)
            schema
          end
        end.first
      end

      # The API this document belongs to, as its schemas are named: `ClientServer` keeps its schemas in `client_server`.
      #
      # @returns [String] the API.
      def api_name
        Operations.underscore(self.class.namespace.name.split("::").last).to_s
      end
    end
  end
end
