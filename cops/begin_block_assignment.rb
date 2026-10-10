# frozen_string_literal: true

# Flags `lvar = begin ... end` (a kwbegin used as rvalue). Rewrite as
#
#   begin
#     lvar = ...
#   end
#
# so the assignment reads left-to-right and the rescue/ensure clauses aren't
# hiding behind the variable name.
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
