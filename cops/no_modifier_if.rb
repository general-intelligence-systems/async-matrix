# frozen_string_literal: true

# Bans the modifier `if` / `unless` (trailing conditional) form:
#
#   return true if task.state_task_completed?     # NO
#
#   if task.state_task_completed?                 # YES
#     return true
#   end
#
# Modifier form hides the guard and mixes control flow with the statement it
# guards; the block form makes both the condition and the branch obvious.
module RuboCop
  module Cop
    module Local
      class NoModifierIf < Base
        extend AutoCorrector

        MSG = "Do not use modifier `%<keyword>s`; use the full `%<keyword>s ... end` block form."

        def on_if(node)
          if node.modifier_form?
            add_offense(node, message: format(MSG, keyword: node.keyword)) do |corrector|
              if safe_to_unwrap?(node)
                corrector.replace(node, block_form(node))
              end
            end
          end
        end

        private

          # Two shapes are left for a human. A modifier that is not the whole
          # statement (`x = (foo if bar)`) would unwrap into a conditional
          # assignment — trading this offence for a NoConditionalAssignment one.
          # A heredoc body's content lives on the lines BELOW the node, outside
          # `source`, so re-indenting the node would strip it.
          def safe_to_unwrap?(node)
            own_line?(node) && !contains_heredoc?(node)
          end

          def own_line?(node)
            line = processed_source.lines[node.first_line - 1].to_s
            line[0...node.loc.column].strip.empty?
          end

          def contains_heredoc?(node)
            node.each_descendant(:str, :dstr, :xstr).any? { |n| n.respond_to?(:heredoc?) && n.heredoc? }
          end

          def block_form(node)
            indent = " " * node.loc.column
            body   = node.if_branch || node.else_branch

            "#{node.keyword} #{node.condition.source}\n" \
              "#{reindent(body, indent)}\n" \
              "#{indent}end"
          end

          # Move the body to a new indent. Only line 1 is positioned absolutely —
          # `source` has already stripped its leading whitespace. Lines 2..n
          # still carry their ORIGINAL absolute indentation, so they get shifted
          # by the delta, which keeps a multi-line body's internal shape intact.
          def reindent(node, indent)
            target = indent.length + 2
            delta  = target - node.loc.column
            lines  = node.source.lines

            rest = lines[1..].to_a.map { |line|
              if delta.negative?
                line.chomp.sub(/\A {0,#{-delta}}/, "")
              else
                "#{' ' * delta}#{line.chomp}"
              end
            }

            [("#{' ' * target}#{lines.first.chomp}")].concat(rest).join("\n")
          end
      end
    end
  end
end
