# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix"
require "async/matrix/client_context"

# The schemas say which classes the library needs. For each of them:
#
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

  REQUIRED.each do |name|
    source = File.join(CLASSES, "#{name}.rb")
    test = source.sub(CLASSES, File.join("test", "async", "matrix", "api", "client_server"))

    it "has class #{source}" do
      expect(File).to be(:exist?, File.join(ROOT, source))
    end

    it "includes the operations context in #{test}" do
      # Loading the file builds the contexts it describes, so the fixture can be looked for where it
      # actually ends up - in the ancestors - rather than in the text of the file.
      contexts = Sus::File[File.join(ROOT, test)].children.each_value.select do |child|
        child.respond_to?(:ancestors)
      end

      expect(contexts).not.to be(:empty?)

      expect(contexts.reject{|context| context.ancestors.include?(Async::Matrix::OperationsContext)}).to be(:empty?)
    end
  end
end
