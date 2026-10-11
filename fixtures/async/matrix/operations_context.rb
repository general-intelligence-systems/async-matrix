# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "yaml"

require "async/matrix/operations"

require_relative "client_context"

module Async
  module Matrix
    # Which operations a test owes, and which cases it has.
    module Operations
      # Where the schemas of every API are, one directory per API.
      SCHEMAS_ROOT = File.expand_path("../../../lib/async/matrix/abstract/api", __dir__)

      # The specification has five APIs, and a test is for whichever one its path names.
      APIS = Dir.children(SCHEMAS_ROOT).select{|name| File.directory?(File.join(SCHEMAS_ROOT, name, "schemas"))}.sort.freeze

      # A case is named exactly `can <operation>`, so that ordinary English - `can page backwards through the timeline` - is not mistaken for naming an operation called `page`.
      PATTERN = /\Acan\s+(?<operation>\S+)\z/

      class << self
        # The API a path belongs to, which is the directory beneath `api`.
        #
        # @parameter path [String] a path under `lib` or `test`.
        # @returns [String | nil] the API, e.g. `client_server`.
        def api_for(path)
          segments = path.to_s.split(File::SEPARATOR)
          index = segments.rindex("api")

          if index
            segments[index + 1]
          end
        end

        # Where one API's schemas are.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @returns [String] the directory.
        def schemas_for(api)
          File.join(SCHEMAS_ROOT, api.to_s, "schemas")
        end

        # The concepts one API names, which is one schema manifest each.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @returns [Array(String)] the concepts, named as a Ruby file would be.
        def concepts_for(api)
          Dir.glob(File.join(self.schemas_for(api), "*-#{Async::Matrix::TEST_VERSION}.yaml")).filter_map do |path|
            if path.end_with?(".deltas.yaml")
              next
            end

            File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml").tr("-", "_")
          end.sort
        end

        # The operations the schema lists for the concept a test describes, taken from its path, since a test mirrors the class it describes.
        #
        # @returns [Hash] the operations, by ID.
        def for(path)
          concept = File.basename(path, ".rb")
          api = self.api_for(path)

          if api
            # The schema keeps the specification's own name, which may be hyphenated where a Ruby file cannot be: `authed-content-repo.yaml` could not be required as `authed-content-repo.rb`.
            schema = [concept, concept.tr("_", "-")].uniq.lazy.map do |name|
              File.join(self.schemas_for(api), "#{name}-#{Async::Matrix::TEST_VERSION}.yaml")
            end.find{|candidate| File.exist?(candidate)}
          end

          if schema
            YAML.safe_load_file(schema)["operations"] || {}
          else
            {}
          end
        end

        # Every operation ID the version under test defines.
        #
        # A case may be named after an operation belonging to another concept's schema.
        #
        # @returns [Array(String)] every operation ID.
        def defined
          @defined ||= Dir.glob(File.join(SCHEMAS_ROOT, "*", "schemas", "*-#{Async::Matrix::TEST_VERSION}.yaml")).each_with_object([]) do |path, found|
            if path.end_with?(".deltas.yaml")
              next
            end

            found.concat((YAML.safe_load_file(path)["operations"] || {}).keys)
          end.freeze
        end

        # The description of every case a context defines, however deeply nested.
        #
        # @parameter context [Sus::Context] the context to walk.
        # @returns [Array(String)] every description.
        def cases(context)
          context.children.each_value.flat_map do |child|
            if child.respond_to?(:children) and !child.leaf?
              self.cases(child)
            else
              [child.description]
            end
          end
        end

        # The operation a case is named after, if it is named after one.
        #
        # @parameter description [String] the case description.
        # @returns [String | nil] the operation ID.
        def operation(description)
          match = PATTERN.match(description.to_s)

          if match and self.defined.include?(match[:operation])
            match[:operation]
          end
        end
      end
    end

    # Included by a test which exercises the specification's operations. It does two things.
    #
    # It checks that the test has a case for every operation the schema lists for the concept it describes, and it wraps every case: one named after an operation must make an HTTP call. The suite only ever runs against a real Synapse, so a case called `can createRoom` which creates no room is worse than no case at all, and that is the one failure which cannot be found by reading the source.
    #
    # @example
    #   describe Async::Matrix::ClientServer::Room do
    #     include Async::Matrix::ClientContext
    #     include Async::Matrix::OperationsContext
    #
    # @example
    #     it "can createRoom" do
    #       expect(client.create_room(name: "Test").id).to be =~ /\A!/
    #     end
    #   end
    OperationsContext = Sus::Shared("operations") do
      Operations.for(self.identity.path).each_key do |operation|
        it "has a case for #{operation}" do
          expect(Operations.cases(self.class.superclass)).to be(:include?, "can #{operation}")
        end
      end

      around do |&block|
        # `receive` with no return value spies rather than replaces, so the request still happens, and its call count defaults to at least once - which sus checks once the body has run.
        if Operations.operation(self.class.description)
          expect(unauthenticated.delegate).to receive(:call)
        end

        super(&block)
      end
    end
  end
end
