# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "yaml"

require "async/matrix"
require "async/matrix/operations"

require_relative "client_context"
require_relative "operations_context"

module Async
  module Matrix
    # What one API owes, measured against its own schemas.
    module ApiContext
      ROOT = File.expand_path("../../..", __dir__)

      # Where an API's classes are, and where its tests are.
      CLASSES = File.join("lib", "async", "matrix", "api")

      TESTS = File.join("test", "async", "matrix", "api")

      class << self
        # The namespace an API's classes live in, where they have been written.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @returns [Module | nil] the namespace, or nil where the API has no classes.
        def namespace_for(api)
          name = api.split("_").map(&:capitalize).join

          if Async::Matrix.const_defined?(name, false)
            Async::Matrix.const_get(name, false)
          end
        end

        # Every operation the version under test defines, with the concept which owns it.
        #
        # @parameter api [String] the API.
        # @returns [Hash] the concept, by operation ID.
        def operations_for(api)
          self.manifests_for(api, Async::Matrix::TEST_VERSION).each_with_object({}) do |path, found|
            concept = File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml").tr("-", "_")

            (YAML.safe_load_file(path)["operations"] || {}).each_key do |operation|
              found[operation] = concept
            end
          end
        end

        # The method name every operation asks for, whichever version defines it.
        #
        # Keyed by method name, because the surface is a list of names.
        #
        # @parameter api [String] the API.
        # @returns [Hash] the operation ID, by method name.
        def elsewhere_for(api)
          self.manifests_for(api, "v*").each_with_object({}) do |path, found|
            (YAML.safe_load_file(path)["operations"] || {}).each_key do |operation|
              found[Async::Matrix::Operations.method_name(operation)] ||= operation
            end
          end
        end

        # Every public method an API offers, wherever it is defined.
        #
        # An operation belongs to the class it reads best on: `createRoom` is a method of the client.
        #
        # @parameter api [Module] the built API to search.
        # @returns [Array(Symbol)] every method name.
        def methods_of(api)
          api.constants.each_with_object([]) do |name, found|
            value = api.const_get(name)

            if value.is_a?(Class)
              found.concat(value.public_instance_methods - Object.public_instance_methods)
              found.concat(value.singleton_methods)
            end
          end.uniq
        end

        # The names a layer declared, by whichever of its registers is asked for.
        #
        # @parameter api [Module] the built API to search.
        # @parameter register [Symbol] `:removals` or `:moves`.
        # @returns [Array(Symbol)] the method names.
        def withdrawals_of(api, register)
          api.constants.each_with_object([]) do |name, found|
            value = api.const_get(name)

            if value.is_a?(Class)
              value.ancestors.each do |ancestor|
                if ancestor.is_a?(Async::Matrix::Removals)
                  found.concat(ancestor.public_send(register).keys)
                end
              end
            end
          end.uniq
        end

        # The schema manifests of an API at a version, which may be a glob.
        #
        # @parameter api [String] the API.
        # @parameter version [String] a version, or `v*` for all of them.
        # @returns [Array(String)] the paths.
        def manifests_for(api, version)
          Dir.glob(File.join(Async::Matrix::Operations.schemas_for(api), "*-#{version}.yaml")).reject do |path|
            path.end_with?(".deltas.yaml")
          end
        end

        # The cases one API owes.
        #
        # @parameter api [String] the API, e.g. `client_server`.
        # @returns [Sus::Shared] the cases.
        def for(api)
          namespace = self.namespace_for(api)
          operations = self.operations_for(api)
          elsewhere = self.elsewhere_for(api)
          owed = operations.keys.map{|operation| Async::Matrix::Operations.method_name(operation)}

          if namespace
            built = Async::Matrix::Versions[Async::Matrix::TEST_VERSION, namespace]
            methods = self.methods_of(built)
            removed = self.withdrawals_of(built, :removals)
            moved = self.withdrawals_of(built, :moves)
          else
            methods = []
            removed = []
            moved = []
          end

          Sus::Shared("the #{api} api") do
            # The classes are what the schemas name, so an API whose schemas are generated and whose classes are not written is a list of failures rather than a silence.
            it "has a namespace" do
              expect(namespace).not.to be_nil
            end

            Async::Matrix::Operations.concepts_for(api).each do |concept|
              source = File.join(CLASSES, api, "#{concept}.rb")

              it "has class #{source}" do
                expect(File).to be(:exist?, File.join(ROOT, source))
              end
            end

            # The specification names every operation, and the library owes each one a method of that name.
            #
            # A case named after an operation proves the method reaches the homeserver. This proves the method is the one the specification asked for, which is the whole point: a method invented here is a method no reader of the specification can find.
            operations.each do |operation, concept|
              if File.exist?(File.join(ROOT, CLASSES, api, "#{concept}.rb"))
                it "has a method named #{Async::Matrix::Operations.method_name(operation)} for #{operation}" do
                  expect(methods).to be(:include?, Async::Matrix::Operations.method_name(operation))
                end
              end
            end

            # An operation another version defines is a method this one must not answer.
            #
            # The check above is one-directional, and so is the context which demands a case per operation: both read the version under test, so a method it has no operation for is invisible to them. A method written into the class rather than into a layer is exactly that - present whatever the version, against a homeserver which does not implement it - and this is where it shows up.
            (elsewhere.keys - owed).each do |name|
              it "has no method named #{name}, which #{Async::Matrix::TEST_VERSION} has no operation for" do
                expect(methods - removed - moved).not.to be(:include?, name)
              end
            end

            # A withdrawal says the version has lost the operation, so the version must not also define it.
            removed.each do |name|
              it "withdraws #{name}, which #{Async::Matrix::TEST_VERSION} has no operation for" do
                expect(owed).not.to be(:include?, name)
              end
            end

            # A move says the operation went to another class, which is the opposite claim: the version still has it, and something else must answer for it.
            moved.each do |name|
              it "moves #{name}, which #{Async::Matrix::TEST_VERSION} still has an operation for" do
                expect(owed).to be(:include?, name)
              end
            end

            # `lib` and `test` mirror each other, and a test which describes a class the specification named carries the context which demands a case per operation.
            Async::Matrix::Operations.concepts_for(api).each do |concept|
              source = File.join(CLASSES, api, "#{concept}.rb")
              test = File.join(TESTS, api, "#{concept}.rb")

              if File.exist?(File.join(ROOT, source))
                it "includes the operations context in #{test}" do
                  # Loading the file builds the contexts it describes, so the fixture can be looked for where it actually ends up - in the ancestors - rather than in the text of the file.
                  contexts = Sus::File[File.join(ROOT, test)].children.each_value.select do |child|
                    child.respond_to?(:ancestors)
                  end

                  expect(contexts).not.to be(:empty?)

                  expect(contexts.reject{|context| context.ancestors.include?(Async::Matrix::OperationsContext)}).to be(:empty?)
                end
              end
            end
          end
        end
      end
    end
  end
end
