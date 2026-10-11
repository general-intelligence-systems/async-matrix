# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "yaml"

require "async/matrix"
require "async/matrix/client_context"
require "async/matrix/operations_context"

# The schemas say which classes the library needs. For each of them:
#
# @example
#   1. the class exists, and
#   2. its test includes {Async::Matrix::OperationsContext}, which is what holds a case named after
#      an operation to actually calling the homeserver.
describe Async::Matrix do
  ROOT = File.expand_path("..", __dir__)

  SCHEMAS = File.join("lib", "async", "matrix", "abstract", "api", "client_server", "schemas")

  CLASSES = File.join("lib", "async", "matrix", "api", "client_server")

  # One per schema manifest, named after it.
  REQUIRED = Dir.glob(File.join(ROOT, SCHEMAS, "*-#{Async::Matrix::TEST_VERSION}.yaml")).filter_map do |path|
    if path.end_with?(".deltas.yaml")
      next
    end

    File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml").tr("-", "_")
  end.sort.freeze

  # Every operation the version under test defines, with the concept which owns it.
  OPERATIONS = Dir.glob(File.join(ROOT, SCHEMAS, "*-#{Async::Matrix::TEST_VERSION}.yaml")).each_with_object({}) do |path, found|
    if path.end_with?(".deltas.yaml")
      next
    end

    concept = File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml").tr("-", "_")

    (YAML.safe_load_file(path)["operations"] || {}).each_key do |operation|
      found[operation] = concept
    end
  end.freeze

  # Every public method the API offers, wherever it is defined.
  #
  # An operation belongs to the class it reads best on: `createRoom` is a method of the client.
  #
  # @parameter api [Module] the API to search.
  # @returns [Array(Symbol)] every method name.
  def self.methods_of(api)
    api.constants.each_with_object([]) do |name, found|
      value = api.const_get(name)

      if value.is_a?(Class)
        found.concat(value.public_instance_methods - Object.public_instance_methods)
        found.concat(value.singleton_methods)
      end
    end.uniq
  end

  API = Async::Matrix::ClientServer::Client[Async::Matrix::TEST_VERSION].api

  METHODS = self.methods_of(API).freeze

  # The specification names every operation, and the library owes each one a method of that name.
  #
  # A case named after an operation proves the method reaches the homeserver. This proves the method is the one the specification asked for, which is the whole point: a method invented here is a method no reader of the specification can find.
  OPERATIONS.each do |operation, concept|
    if File.exist?(File.join(ROOT, CLASSES, "#{concept}.rb"))
      it "has a method named #{Async::Matrix::Operations.method_name(operation)} for #{operation}" do
        expect(METHODS).to be(:include?, Async::Matrix::Operations.method_name(operation))
      end
    end
  end

  REQUIRED.each do |name|
    source = File.join(CLASSES, "#{name}.rb")
    test = source.sub(CLASSES, File.join("test", "async", "matrix", "api", "client_server"))

    it "has class #{source}" do
      expect(File).to be(:exist?, File.join(ROOT, source))
    end

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
