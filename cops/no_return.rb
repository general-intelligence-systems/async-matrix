# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Bans the `return` keyword.
#
# @example
#   if cond          →    if cond
#     return X              X
#   end                   else
#   rest                    rest
#                         end

require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class NoReturn < Base
        include PrismSource
        extend AutoCorrector

        MSG = "Do not use `return`; let the method's last expression be the return value."

        def on_new_investigation
          # One guard per body per pass — two corrections inside the same body would overlap and clobber each other. `rubocop -a` re-runs the cop until it stops changing anything, so chained guards still unwind, one per pass.
          @corrected_bodies = {}

          self.prism_each(::Prism::ReturnNode).each do |node|
            self.report(node)
          end
        end

        private

        def report(node)
          add_offense(self.prism_node_range(node)) do |corrector|
            guard = self.correctable_guard(node)

            if guard
              body, index = guard

              if @corrected_bodies[body.object_id].nil?
                @corrected_bodies[body.object_id] = true
                corrector.replace(self.replaced_range(body, index), self.rewritten(body, index))
              end
            end
          end
        end

        # The guard's body and index, when the node is one.
        #
        # Prism writes a `StatementsNode` between a conditional and its body, so the guard is the `return`'s grandparent.
        def correctable_guard(node)
          statements = self.prism_parent(node)

          if !statements.is_a?(::Prism::StatementsNode)
            nil
          else
            if_node = self.prism_parent(statements)

            if self.unguarded?(if_node, statements, node)
              nil
            else
              body = self.prism_parent(if_node)

              if !body.is_a?(::Prism::StatementsNode) || !self.tail_position?(body)
                nil
              else
                index = body.body.index(if_node)

                if index.nil? || index == body.body.size - 1
                  nil
                else
                  [body, index]
                end
              end
            end
          end
        end

        # Every shape which is not a plain `if cond / return X / end` guard.
        def unguarded?(if_node, statements, node)
          !self.conditional?(if_node) ||
            self.modifier_form?(if_node) ||
            self.ternary?(if_node) ||
            self.elsif?(if_node) ||
            !if_node.statements.equal?(statements) ||
            statements.body != [node] ||
            !self.else_branch(if_node).nil?
        end

        def conditional?(node)
          node.is_a?(::Prism::IfNode) || node.is_a?(::Prism::UnlessNode)
        end

        # A modifier has its keyword written after what it guards, and so has no `end` to close.
        def modifier_form?(node)
          !self.keyword_location(node).nil? && node.end_keyword_loc.nil?
        end

        # A ternary has no keyword at all.
        def ternary?(node)
          self.keyword_location(node).nil?
        end

        # An `elsif` is a conditional whose keyword says so.
        def elsif?(node)
          location = self.keyword_location(node)

          !location.nil? && self.prism_range(location).source == "elsif"
        end

        def keyword_location(node)
          if node.is_a?(::Prism::UnlessNode)
            node.keyword_loc
          else
            node.if_keyword_loc
          end
        end

        # What follows the then-branch: an `else`, or a chained `elsif`.
        def else_branch(node)
          if node.is_a?(::Prism::UnlessNode)
            node.else_clause
          else
            node.subsequent
          end
        end

        def keyword(node)
          if node.is_a?(::Prism::UnlessNode)
            "unless"
          else
            "if"
          end
        end

        # Whether this node is the last thing its enclosing method evaluates.
        def tail_position?(node)
          parent = self.prism_parent(node)

          if parent.nil?
            false
          elsif parent.is_a?(::Prism::DefNode)
            parent.body.equal?(node)
          elsif parent.is_a?(::Prism::StatementsNode)
            parent.body.last.equal?(node) && self.tail_position?(parent)
          elsif parent.is_a?(::Prism::ElseNode)
            parent.statements.equal?(node) && self.tail_position?(parent)
          elsif self.conditional?(parent) && !self.ternary?(parent)
            parent.statements.equal?(node) && self.tail_position?(parent)
          else
            false
          end
        end

        def replaced_range(body, index)
          first = body.body[index].location
          last = body.body.last.location

          ::Parser::Source::Range.new(processed_source.buffer, first.start_offset, last.end_offset)
        end

        def rewritten(body, index)
          if_node = body.body[index]
          indent = " " * if_node.location.start_column
          guarded = self.returned_value(if_node)
          rest = body.body[(index + 1)..]

          if guarded
            guard_value = self.reindent(guarded, indent)
          else
            guard_value = "#{indent}  nil"
          end
          rest_source = rest.map{|statement| self.reindent(statement, indent)}.join("\n")

          # `unless cond / return X / end` means "X unless cond", so the branches swap rather than the condition being negated.
          if self.keyword(if_node) == "unless"
            first, second = rest_source, guard_value
          else
            first, second = guard_value, rest_source
          end

          "if #{self.prism_source(if_node.predicate)}\n#{first}\n#{indent}else\n#{second}\n#{indent}end"
        end

        # The value the guard returns, or nil for a bare `return`.
        def returned_value(if_node)
          if_node.statements.body.first.arguments&.arguments&.first
        end

        # Move a statement to a new indent.
        def reindent(node, indent)
          target = indent.length + 2
          delta = target - node.location.start_column
          lines = self.prism_source(node).lines

          rest = lines[1..].to_a.map{|line|
            if delta.negative?
              line.chomp.sub(/\A {0,#{-delta}}/, "")
            else
              "#{" " * delta}#{line.chomp}"
            end
          }

          [("#{" " * target}#{lines.first.chomp}")].concat(rest).join("\n")
        end
      end
    end
  end
end
