# frozen_string_literal: true

# Bans the modifier `if` / `unless` form.
#
# @example
#   return true if task.state_task_completed?     # NO
#
# @example
#   if task.state_task_completed?                 # YES
#     return true
#   end
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

        # Two shapes are left for a human.
        def safe_to_unwrap?(node)
          own_line?(node) && !contains_heredoc?(node)
        end

        def own_line?(node)
          line = processed_source.lines[node.first_line - 1].to_s
          line[0...node.loc.column].strip.empty?
        end

        def contains_heredoc?(node)
          node.each_descendant(:str, :dstr, :xstr).any?{|n| n.respond_to?(:heredoc?) && n.heredoc?}
        end

        def block_form(node)
          indent = " " * node.loc.column
          body   = node.if_branch || node.else_branch

          "#{node.keyword} #{node.condition.source}\n" \
            "#{reindent(body, indent)}\n" \
            "#{indent}end"
        end

        # Move the body to a new indent.
        def reindent(node, indent)
          target = indent.length + 2
          delta  = target - node.loc.column
          lines  = node.source.lines

          rest = lines[1..].to_a.map{|line|
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
