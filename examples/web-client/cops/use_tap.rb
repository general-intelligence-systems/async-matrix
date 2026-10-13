# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class UseTap < Base
        include PrismSource

        MSG = "Assigning `%<name>s` and returning it at the end is `tap`; " \
              "write `<expression>.tap do |%<name>s| ... end`."

        REASSIGNMENTS = [
          ::Prism::LocalVariableWriteNode,
          ::Prism::LocalVariableOperatorWriteNode,
          ::Prism::LocalVariableOrWriteNode,
          ::Prism::LocalVariableAndWriteNode,
          ::Prism::MultiWriteNode,
        ].freeze

        def on_new_investigation
          self.prism_each(::Prism::DefNode).each do |node|
            self.check(node.body)
          end
        end

        private

        def check(body)
          if self.tap_shaped?(body)
            add_offense(self.prism_node_range(body), message: format(MSG, name: self.assigned_name(body)))
          end
        end

        def tap_shaped?(body)
          body.is_a?(::Prism::StatementsNode) &&
            body.body.size >= 2 &&
            body.body.first.is_a?(::Prism::LocalVariableWriteNode) &&
            self.returns_assigned?(body) &&
            !self.reassigned?(body)
        end

        def assigned_name(body)
          body.body.first.name
        end

        def returns_assigned?(body)
          last = body.body.last

          last.is_a?(::Prism::LocalVariableReadNode) && last.name == self.assigned_name(body)
        end

        def reassigned?(body)
          name = self.assigned_name(body)

          body.body[1..-2].any? do |statement|
            [statement].concat(self.prism_descendants(statement)).any? do |write|
              REASSIGNMENTS.any?{|klass| write.is_a?(klass)} && self.writes_name?(write, name)
            end
          end
        end

        def writes_name?(node, name)
          if node.is_a?(::Prism::MultiWriteNode)
            node.lefts.concat(node.rights).any? do |target|
              target.respond_to?(:name) && target.name == name
            end
          else
            node.name == name
          end
        end
      end
    end
  end
end
