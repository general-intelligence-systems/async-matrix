# frozen_string_literal: true

# Flags a `begin ... end` assigned to a variable.
#
# @example
#   begin
#     lvar = ...
#   end
module RuboCop
  module Cop
    module Local
      class BeginBlockAssignment < Base
        MSG = "Do not assign a `begin...end` expression to a variable; " \
              "move the assignment inside the begin block."

        def on_lvasgn(node)
          check(node)
        end
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn

        private

        def check(node)
          rhs = node.children.last
          if rhs.is_a?(RuboCop::AST::Node) && rhs.type == :kwbegin
            add_offense(node)
          end
        end
      end
    end
  end
end
