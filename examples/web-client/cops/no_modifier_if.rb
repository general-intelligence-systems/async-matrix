# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Bans the modifier `if` / `unless` form.
#
# @example
#   return true if task.state_task_completed?     # NO
#
# @example
#   if task.state_task_completed?                 # YES
#     return true
#   end

require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class NoModifierIf < Base
        include PrismSource
        extend AutoCorrector

        MSG = "Do not use modifier `%<keyword>s`; use the full `%<keyword>s ... end` block form."

        def on_new_investigation
          self.prism_each(::Prism::IfNode, ::Prism::UnlessNode).each do |node|
            if self.modifier_form?(node)
              range = self.prism_node_range(node)

              add_offense(range, message: format(MSG, keyword: self.keyword(node))) do |corrector|
                if self.safe_to_unwrap?(node)
                  corrector.replace(range, self.block_form(node))
                end
              end
            end
          end
        end

        private

        # A modifier has its keyword written after what it guards, and so has no `end` to close.
        # A ternary has no keyword at all, and is not this cop's business.
        def modifier_form?(node)
          if node.is_a?(::Prism::UnlessNode)
            keyword = node.keyword_loc
          else
            keyword = node.if_keyword_loc
          end

          !keyword.nil? && node.end_keyword_loc.nil?
        end

        def keyword(node)
          if node.is_a?(::Prism::UnlessNode)
            "unless"
          else
            "if"
          end
        end

        # Two shapes are left for a human.
        def safe_to_unwrap?(node)
          self.own_line?(node) && !self.prism_heredoc?(node)
        end

        def own_line?(node)
          line = processed_source.lines[node.location.start_line - 1].to_s

          line[0...self.prism_column(node)].strip.empty?
        end

        def block_form(node)
          indent = " " * self.prism_column(node)
          body = node.statements

          "#{self.keyword(node)} #{self.prism_source(node.predicate)}\n" \
            "#{self.reindent(body, indent)}\n" \
            "#{indent}end"
        end

        # Move the body to a new indent.
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
