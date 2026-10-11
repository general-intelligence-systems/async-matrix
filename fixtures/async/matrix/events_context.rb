# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "yaml"

require "async/matrix/events"

require_relative "client_context"

module Async
  module Matrix
    # Which events a test owes, and what each carries.
    module EventSchemas
      SCHEMAS = File.expand_path("../../../lib/async/matrix/abstract/events/schemas", __dir__)

      # A case is named exactly `can <type>`, as the operations are, so that a case which exercises a type end to end can be told from one which describes a detail of it.
      PATTERN = /\Acan\s+(?<type>\S+)\z/

      # A content field whose name cannot be an accessor, and the names which read it instead.
      #
      # Three kinds appear. A name every object answers to - `methods`, `hash` - would be overridden.
      # A name this library already uses would read the wrong thing: `type` is the event type and `version` is the specification version, so `m.room.create` and the call events need their own. And a name which is not an identifier at all - the dotted fields, and the `(*)` of content keyed by a pattern, which is read by iterating it.
      #
      # More than one name per field, because the type it belongs to decides what it is called: the `type` of `m.room.create` is the kind of room, and the `type` of `m.room.message.feedback` is the kind of feedback. A class satisfies the field by reading it under any of them.
      RENAMED = {
        "methods" => [:verification_methods],
        "method" => [:verification_method],
        "hash" => [:hash_method],
        "type" => [:room_type, :feedback_type],
        "version" => [:voip_version],
        "(*)" => [:each],
      }.freeze

      class << self
        # Every family the version under test describes. A family is one schema manifest: a type and its variants, which is what one Ruby file holds.
        #
        # @returns [Array(String)] the type of each family.
        def families
          @families ||= Dir.glob(File.join(SCHEMAS, "*-#{Async::Matrix::TEST_VERSION}.yaml")).filter_map do |path|
            unless path.end_with?(".deltas.yaml")
              File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml")
            end
          end.sort.freeze
        end

        # The file a family is described by, with the leading `m.` stripped.
        #
        # @parameter family [String] the type of the family.
        # @returns [String] the file name, without a suffix.
        def file_name(family)
          family.delete_prefix("m.").tr(".", "_")
        end

        # The family a test describes, taken from its path.
        #
        # The mapping is applied forwards rather than guessed backwards, because a type may carry an underscore.
        #
        # @parameter path [String] the path of the test.
        # @returns [String | nil] the type of the family.
        def family_for(path)
          concept = File.basename(path, ".rb")

          self.families.find{|family| self.file_name(family) == concept}
        end

        # What the schema says a family carries.
        #
        # @parameter family [String] the type of the family.
        # @returns [Hash] each entry, by its key in the schema.
        def entries(family)
          path = File.join(SCHEMAS, "#{family}-#{Async::Matrix::TEST_VERSION}.yaml")

          if File.exist?(path)
            YAML.safe_load_file(path)["events"] || {}
          else
            {}
          end
        end

        # The class the version under test reads an entry as.
        #
        # @parameter entry [Hash] the schema entry.
        # @returns [Class] the content class.
        def content_class(entry)
          variant = (entry["variant"] || {}).each_with_object({}) do |(field, value), fields|
            fields[field.to_sym] = value
          end

          Events.registry(Async::Matrix::TEST_VERSION).content_class(entry["type"], variant)
        end

        # Whether a field is read by an accessor this library defines.
        #
        # `instance_methods` alone is not enough: a field named after `methods` or `hash` would appear read.
        #
        # @parameter klass [Class] the content class.
        # @parameter field [String] the field the schema declares.
        # @returns [Boolean] whether it is reachable.
        def reads?(klass, field)
          names = RENAMED.fetch(field, [field.to_sym])

          names.any? do |name|
            if klass.instance_methods.include?(name)
              klass.instance_method(name).owner.to_s.start_with?("Async::Matrix")
            else
              false
            end
          end
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

        # The type a case is named after, if it is named after one.
        #
        # @parameter description [String] the case description.
        # @returns [String | nil] the type.
        def type(description)
          match = PATTERN.match(description.to_s)

          if match and self.families.include?(match[:type])
            match[:type]
          end
        end
      end
    end

    # Included by a test which describes a family of events. It checks the library against the schema rather than against itself: the accessors are one line each, so what can go wrong is not an accessor but the correspondence - a field the schema declares and nothing reads, a variant dispatched on the wrong value, a type framed as the wrong kind of event.
    #
    # A case named `can <type>` is held to reaching the homeserver, as the operations are, so that a round trip which does not actually round trip fails. Such a case is not required, because a client cannot send every type: some are sent by the server, and some only through an endpoint of their own.
    #
    # @example
    #   describe Async::Matrix::Events::Message do
    #     include Async::Matrix::ClientContext
    #     include Async::Matrix::EventsContext
    #   end
    EventsContext = Sus::Shared("events") do
      family = EventSchemas.family_for(self.identity.path)

      EventSchemas.entries(family.to_s).each do |key, entry|
        klass = EventSchemas.content_class(entry)

        it "has a class for #{key}" do
          expect(klass.event_type).to be == entry["type"]
        end

        it "frames #{key} as the schema does" do
          expect(klass.framing.to_s).to be == entry["framing"]
        end

        if variant = entry["variant"]
          it "dispatches #{key} on the field which distinguishes it" do
            expected = variant.each_with_object({}){|(field, value), fields| fields[field.to_sym] = value}

            expect(klass.variant).to be == expected
          end
        end

        # The schema writes a content which declares no fields of its own as the bare type it is - `content: object` - where one with fields is a map of them. There is nothing to read either way, so a scalar is no fields.
        declared = entry["content"]

        if declared.is_a?(Hash)
          content = declared
        else
          content = {}
        end

        content.each_key do |field|
          it "reads the #{field} of #{key}" do
            expect(EventSchemas.reads?(klass, field)).to be == true
          end
        end
      end

      around do |&block|
        # `receive` with no return value spies rather than replaces, so the request still happens, and its call count defaults to at least once - which sus checks once the body has run.
        if EventSchemas.type(self.class.description)
          expect(unauthenticated.delegate).to receive(:call)
        end

        super(&block)
      end
    end
  end
end
