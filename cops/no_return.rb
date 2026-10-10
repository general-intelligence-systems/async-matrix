# frozen_string_literal: true

# Bans the `return` keyword. A method's last expression is its return value;
# early exits must be expressed through `if` / `unless` / `case` structure,
# not by short-circuiting out of the middle of a block.
#
# Autocorrection handles ONE shape — the guard clause at the top level of a
# method body:
#
#   if cond          →    if cond
#     return X              X
#   end                   else
#   rest                    rest
#                         end
#
# Everything else (a `return` inside a block, a loop, or a `rescue`) is left
# alone: unwinding those changes which construct the value escapes from, and
# there is no rewrite that is correct without reading the surrounding intent.
module RuboCop
  module Cop
    module Local
      class NoReturn < Base
        extend AutoCorrector

        MSG = "Do not use `return`; let the method's last expression be the return value."

        def on_new_investigation
          super
          # One guard per body per pass — two corrections inside the same body
          # would overlap and clobber each other. `rubocop -a` re-runs the cop
          # until it stops changing anything, so chained guards still unwind,
          # one per pass.
          @corrected_bodies = {}
        end

        def on_return(node)
          add_offense(node) do |corrector|
            guard = correctable_guard(node)
            if guard
              body, index = guard
              if @corrected_bodies[body.object_id].nil?
                @corrected_bodies[body.object_id] = true
                corrector.replace(replaced_range(body, index), rewritten(body, index))
              end
            end
          end
        end

        private

          # Returns [body_node, index_of_guard] when +node+ is the whole body of
          # an `if`/`unless` that is itself a plain statement in a method body
          # with at least one statement after it. Otherwise nil.
          def correctable_guard(node)
            if_node = node.parent

            if if_node.nil? || if_node.type != :if || if_node.modifier_form? ||
               if_node.ternary? || if_node.elsif? || node != if_node.if_branch ||
               if_node.else_branch
              nil
            else
              body = if_node.parent
              if body.nil? || body.type != :begin || !tail_position?(body)
                nil
              else
                index = body.children.index(if_node)
                if index.nil? || index == body.children.size - 1
                  nil
                else
                  [body, index]
                end
              end
            end
          end

          # "Everything after the guard" is only the method's value if this
          # statement list is in TAIL position — the method body itself, or a
          # branch of a conditional that is itself in tail position (which is
          # what a chain of guards unwinds into, one pass at a time).
          #
          # Recursion stops at anything else, and in particular at a `block`: a
          # `return` inside one exits the enclosing METHOD, not the block, so
          # turning it into a trailing value would change what the block yields.
          # `rescue` / `ensure` bodies stop it too.
          def tail_position?(node)
            parent = node.parent

            if parent.nil?
              false
            elsif %i[def defs].include?(parent.type)
              parent.body == node
            elsif parent.type == :if && !parent.ternary?
              (node == parent.if_branch || node == parent.else_branch) && tail_position?(parent)
            elsif parent.type == :begin
              node == parent.children.last && tail_position?(parent)
            else
              false
            end
          end

          def replaced_range(body, index)
            body.children[index].source_range.join(body.children.last.source_range)
          end

          def rewritten(body, index)
            if_node = body.children[index]
            indent  = " " * if_node.loc.column
            guarded = if_node.if_branch.children.first # the return's value, or nil
            rest    = body.children[(index + 1)..]

            if guarded
              guard_value = reindent(guarded, indent)
            else
              guard_value = "#{indent}  nil"
            end
            rest_source = rest.map { |s| reindent(s, indent) }.join("\n")

            # `unless cond / return X / end` means "X unless cond", so the
            # branches swap rather than the condition being negated.
            if if_node.keyword == "unless"
              first, second = rest_source, guard_value
            else
              first, second = guard_value, rest_source
            end

            "if #{if_node.condition.source}\n#{first}\n#{indent}else\n#{second}\n#{indent}end"
          end

          # Move a statement to a new indent. Only line 1 is positioned
          # absolutely — `source` has already stripped its leading whitespace.
          # Lines 2..n still carry their ORIGINAL absolute indentation, so they
          # get shifted by the delta instead, which is what keeps a multi-line
          # body's internal shape intact.
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
