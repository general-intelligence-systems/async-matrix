# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "yaml"

require "async/matrix/events"

require_relative "client_context"

module Async
  module Matrix
    # What {EventsContext} needs to know: which events a test owes, and what the schema says each
    # of them carries.
    module EventSchemas
      SCHEMAS = File.expand_path("../../../lib/async/matrix/abstract/events/schemas", __dir__)

      # A case is named exactly `can <type>`, as the operations are, so that a case which exercises
      # a type end to end can be told from one which describes a detail of it.
      PATTERN = /\Acan\s+(?<type>\S+)\z/

      # A content field whose name is already a Ruby method, and the accessor which reads it
      # instead. `methods` would override `Object#methods`, which is what introspection calls.
      RENAMED = {
        "methods" => :verification_methods,
      }.freeze

      class << self
        # Every family the version under test describes. A family is one schema manifest: a type
        # and its variants, which is what one Ruby file holds.
        #
        # @returns [Array(String)] the type of each family.
        def families
          @families ||= Dir.glob(File.join(SCHEMAS, "*-#{Async::Matrix::TEST_VERSION}.yaml")).filter_map do |path|
            unless path.end_with?(".deltas.yaml")
              File.basename(path).delete_suffix("-#{Async::Matrix::TEST_VERSION}.yaml")
            end
          end.sort.freeze
        end

        # The file a family is described by. The type's own name is not a valid path - and the
        # leading `m.` says nothing, since every type carries it - so it is stripped and the
        # remaining separators become underscores. `m.room_key_request` already has one.
        #
        # @parameter family [String] the type of the family.
        # @returns [String] the file name, without a suffix.
        def file_name(family)
          family.delete_prefix("m.").tr(".", "_")
        end

        # The family a test describes, taken from its path, since a test mirrors the file it
        # describes. The mapping is applied forwards rather than guessed backwards, because a type
        # may carry an underscore of its own.
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
        # `instance_methods` alone is not enough: a field named after something every object
        # answers to - `methods`, `hash`, `display` - would appear to be read when it is not.
        #
        # @parameter klass [Class] the content class.
        # @parameter field [String] the field the schema declares.
        # @returns [Boolean] whether it is reachable.
        def reads?(klass, field)
          name = RENAMED.fetch(field, field.to_sym)

          if klass.instance_methods.include?(name)
            klass.instance_method(name).owner.to_s.start_with?("Async::Matrix")
          else
            false
          end
        end

        # The description of every case a context defines, however deeply nested.
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
        def type(description)
          match = PATTERN.match(description.to_s)

          if match and self.families.include?(match[:type])
            match[:type]
          end
        end
      end
    end

    # Included by a test which describes a family of events. It checks the library against the
    # schema rather than against itself: the accessors are one line each, so what can go wrong is
    # not an accessor but the correspondence - a field the schema declares and nothing reads, a
    # variant dispatched on the wrong value, a type framed as the wrong kind of event.
    #
    # A case named `can <type>` is held to reaching the homeserver, as the operations are, so that
    # a round trip which does not actually round trip fails. Such a case is not required, because
    # a client cannot send every type: some are sent by the server, and some only through an
    # endpoint of their own.
    #
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

        (entry["content"] || {}).each_key do |field|
          it "reads the #{field} of #{key}" do
            expect(EventSchemas.reads?(klass, field)).to be == true
          end
        end
      end

      around do |&block|
        # `receive` with no return value spies rather than replaces, so the request still happens,
        # and its call count defaults to at least once - which sus checks once the body has run.
        if EventSchemas.type(self.class.description)
          expect(unauthenticated.delegate).to receive(:call)
        end

        super(&block)
      end
    end
  end
end
