# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class NoReturn < Base
        include PrismSource
        extend AutoCorrector

        MSG = "Do not use `return`; let the method's last expression be the return value."

        def on_new_investigation
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

        def modifier_form?(node)
          !self.keyword_location(node).nil? && node.end_keyword_loc.nil?
        end

        def ternary?(node)
          self.keyword_location(node).nil?
        end

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
          self.prism_span(body.body[index].location, body.body.last.location)
        end

        def rewritten(body, index)
          if_node = body.body[index]
          indent = " " * self.prism_column(if_node)
          guarded = self.returned_value(if_node)
          rest = body.body[(index + 1)..]

          if guarded
            guard_value = self.reindent(guarded, indent)
          else
            guard_value = "#{indent}  nil"
          end
          rest_source = rest.map{|statement| self.reindent(statement, indent)}.join("\n")

          if self.keyword(if_node) == "unless"
            first, second = rest_source, guard_value
          else
            first, second = guard_value, rest_source
          end

          "if #{self.prism_source(if_node.predicate)}\n#{first}\n#{indent}else\n#{second}\n#{indent}end"
        end

        def returned_value(if_node)
          if_node.statements.body.first.arguments&.arguments&.first
        end

        def reindent(node, indent)
          target = indent.length + 2
          delta = target - self.prism_column(node)
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
