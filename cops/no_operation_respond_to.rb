# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "support/prism_source"
require_relative "../lib/async/matrix/operations"

module RuboCop
  module Cop
    module AsyncMatrix
      # Bans asking whether an operation is there, which the version already answers.
      #
      # The answer is only a name's presence, which is not what a version means.
      #
      # @example
      #   # bad - the version is what decides this
      #   if client.respond_to?(:get_room_key_by_session_id)
      #     client.get_room_key_by_session_id(room_id, session_id)
      #   end
      #
      # @example
      #   # good - ask for the version which has it
      #   client = Async::Matrix::ClientServer::Client["v1.2"]
      #
      # @example
      #   # good - a withdrawn operation says so itself
      #   begin
      #     client.get_room_keys_by_session_id(room_id, session_id)
      #   rescue Async::Matrix::RemovedOperationError => error
      #     error.replacement
      #   end
      class NoOperationRespondTo < Base
        include PrismSource

        MSG = "`%<method>s(:%<name>s)` asks whether the version has `%<operation>s`. Ask for the version which defines it instead: the built class is the answer."

        # The methods which ask an object what it has.
        PROBES = %i[respond_to? respond_to_missing?].freeze

        # The schemas say which operations exist, every version of them, because a name withdrawn by a later version is exactly the name worth probing for. Override the location with `SchemasPath`.
        DEFAULT_SCHEMAS_PATH = File.expand_path("../lib/async/matrix/abstract/api/client_server/schemas", __dir__)

        # @returns [String] where the schemas are read from.
        def schemas_path
          cop_config.fetch("SchemasPath", DEFAULT_SCHEMAS_PATH)
        end

        # The operation each method name belongs to, whichever version defines it.
        #
        # Read a line at a time: the schemas are 14M of shapes nothing here reads.
        #
        # @returns [Hash] the operation ID, by method name.
        def operations
          @operations ||= Dir.glob(File.join(self.schemas_path, "*-v*.yaml")).each_with_object({}) do |path, found|
            if path.end_with?(".deltas.yaml")
              next
            end

            self.operations_in(path).each do |operation|
              found[::Async::Matrix::Operations.method_name(operation)] ||= operation
            end
          end
        end

        def on_new_investigation
          self.prism_each(::Prism::CallNode).each do |node|
            if PROBES.include?(node.name)
              self.check(node)
            else
              nil
            end
          end
        end

        private

        # The operation IDs a manifest lists, which are the keys written directly under `operations:`.
        def operations_in(path)
          [].tap do |found|
            inside = false

            File.foreach(path) do |line|
              case line
              when /^operations:/
                inside = true
              when /^\S/
                inside = false
              when /^  ([A-Za-z_]\w*):/
                if inside
                  found << $1
                end
              end
            end
          end
        end

        def check(node)
          name = self.probed_name(node)

          if name and self.operations.key?(name)
            add_offense(self.prism_node_range(node), message: format(MSG,
              method: node.name,
              name: name,
              operation: self.operations.fetch(name),
            ))
          end
        end

        # The method name being probed for, where the argument says it literally.
        #
        # Read through the naming rule, so the specification's own name probes the same thing.
        def probed_name(node)
          argument = node.arguments&.arguments&.first

          case argument
          when ::Prism::SymbolNode, ::Prism::StringNode
            ::Async::Matrix::Operations.method_name(argument.unescaped)
          end
        end
      end
    end
  end
end
