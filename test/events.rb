# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/events"
require "async/matrix/events_context"

# The event schemas say which classes the library needs, one file per family: a type and the
# variants which share it. For each of them:
#
#   1. the class file exists, and
#   2. its test includes {Async::Matrix::EventsContext}, which is what holds the classes to what
#      the schema says they carry.
describe Async::Matrix::Events do
  ROOT = File.expand_path("..", __dir__)

  CLASSES = File.join("lib", "async", "matrix", "events")

  TESTS = File.join("test", "async", "matrix", "events")

  Async::Matrix::EventSchemas.families.each do |family|
    name = Async::Matrix::EventSchemas.file_name(family)

    source = File.join(CLASSES, "#{name}.rb")
    test = File.join(TESTS, "#{name}.rb")

    it "has class #{source} for #{family}" do
      expect(File).to be(:exist?, File.join(ROOT, source))
    end

    it "includes the events context in #{test}" do
      # Loading the file builds the contexts it describes, so the fixture can be looked for where
      # it actually ends up - in the ancestors - rather than in the text of the file.
      contexts = Sus::File[File.join(ROOT, test)].children.each_value.select do |child|
        child.respond_to?(:ancestors)
      end

      expect(contexts).not.to be(:empty?)

      expect(contexts.reject{|context| context.ancestors.include?(Async::Matrix::EventsContext)}).to be(:empty?)
    end
  end
end
