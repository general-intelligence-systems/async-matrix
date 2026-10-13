# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class BeginBlockAssignment < Base
        include PrismSource

        MSG = "Do not assign a `begin...end` expression to a variable; " \
              "move the assignment inside the begin block."

        WRITES = [
          ::Prism::LocalVariableWriteNode,
          ::Prism::InstanceVariableWriteNode,
          ::Prism::ClassVariableWriteNode,
          ::Prism::GlobalVariableWriteNode,
        ].freeze

        def on_new_investigation
          self.prism_each(*WRITES).each do |node|
            if node.value.is_a?(::Prism::BeginNode)
              add_offense(self.prism_node_range(node))
            end
          end
        end
      end
    end
  end
end
