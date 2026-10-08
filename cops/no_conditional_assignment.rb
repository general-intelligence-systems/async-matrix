# frozen_string_literal: true

# Bans assigning an `if` / `unless` / `case` expression — including a ternary,
# which is an `if` node — to a variable or through a setter:
#
#   status = case task.state                  # NO
#            when :done then :ok
#            else :pending
#            end
#   obj.status = cond ? :ok : :pending        # NO
#
#   status = :pending                         # YES
#   case task.state
#   when :done
#     status = :ok
#   end
#
# The conditional makes the assignment itself, inside each branch, so the
# target isn't hidden behind a multi-line expression, the branches line up
# under the assignment instead of hanging off its right edge, and adding a
# branch doesn't re-indent the whole expression.
#
# RuboCop ships `Style/ConditionalAssignment` with `assign_inside_condition`,
# but it only fires when every branch is present; `x = if cond ... end` with
# no `else` slips through it.
module RuboCop
  module Cop
    module Local
      class NoConditionalAssignment < Base
        extend AutoCorrector

        MSG = "Do not assign a `%<keyword>s` expression to a variable; " \
              "assign inside each branch of the %<keyword>s."

        CONDITIONAL_TYPES = %i[if case case_match].freeze

        def on_lvasgn(node)
          check(node, node.children.last)
        end
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn
        alias on_casgn on_lvasgn
        alias on_op_asgn on_lvasgn
        alias on_or_asgn on_lvasgn
        alias on_and_asgn on_lvasgn
        alias on_masgn on_lvasgn

        def on_send(node)
          if node.assignment_method?
            check(node, node.last_argument)
          end
        end

        private

          def check(node, rhs)
            if conditional?(rhs)
              add_offense(node, message: format(MSG, keyword: keyword(rhs))) do |corrector|
                if safe_to_push_inside?(node, rhs)
                  corrector.replace(node, pushed_inside(node, rhs))
                end
              end
            end
          end

          # The rewrite repeats the assignment target once per branch, so the
          # target must be re-evaluable without side effects — a bare variable or
          # a simple `recv.attr =`. Anything else (an index write, a call with
          # arguments) is left for a human. A heredoc anywhere in the expression
          # is skipped too: its body lives on the lines below the node, outside
          # `source`, so re-indenting the node would strip it.
          def safe_to_push_inside?(node, rhs)
            # `case/in` pattern matching is left alone — its branch headers are
            # patterns, not expressions, and reproducing them is a different job.
            rhs.type != :case_match &&
              own_line?(node) &&
              simple_target?(node) &&
              !contains_heredoc?(node) &&
              branches(rhs).all? { |_cond, body| body.nil? || !body.source.include?("\n") }
          end

          def simple_target?(node)
            case node.type
            when :lvasgn, :ivasgn, :cvasgn, :gvasgn, :casgn
              true
            when :send
              node.assignment_method? && node.arguments.one? && node.receiver&.type == :send &&
                node.receiver.arguments.empty?
            else
              false
            end
          end

          def own_line?(node)
            line = processed_source.lines[node.first_line - 1].to_s
            line[0...node.loc.column].strip.empty?
          end

          def contains_heredoc?(node)
            node.each_descendant(:str, :dstr, :xstr).any? { |n| n.respond_to?(:heredoc?) && n.heredoc? }
          end

          # The assignment prefix repeated in every branch — "x = ", "@y = ",
          # "obj.z = ".
          def target_source(node)
            if node.type == :send
              "#{node.receiver.source}.#{node.method_name.to_s.chomp('=')} = "
            else
              "#{node.children.first} = "
            end
          end

          # [[condition_source_or_nil, body_node_or_nil], ...] in source order.
          # A nil condition is the `else`; a nil body is an empty branch, which
          # becomes an explicit `= nil` so the variable is always defined.
          def branches(rhs)
            if rhs.type == :if
              if_branches(rhs)
            else
              case_branches(rhs)
            end
          end

          def if_branches(node, acc = [])
            cond, then_body, else_body = *node
            acc << [cond.source, then_body]

            if else_body&.type == :if && !else_body.ternary?
              if_branches(else_body, acc)
            else
              acc << [nil, else_body]
            end

            acc
          end

          def case_branches(node)
            node.when_branches.map { |w| [w, w.body] } + [[nil, node.else_branch]]
          end

          def pushed_inside(node, rhs)
            indent = " " * node.loc.column
            target = target_source(node)

            if rhs.type == :if
              rendered_if(rhs, indent, target)
            else
              rendered_case(rhs, indent, target)
            end
          end

          def rendered_if(rhs, indent, target)
            parts = if_branches(rhs).each_with_index.map { |(cond, body), i|
              if cond.nil?
                header = "#{indent}else"
              elsif i.zero?
                header = "#{indent}if #{cond}"
              else
                header = "#{indent}elsif #{cond}"
              end

              "#{header}\n#{indent}  #{target}#{body ? body.source : 'nil'}"
            }

            # The replacement begins at the node's own column, so the first line
            # must NOT carry the indent again.
            "#{parts.join("\n").sub(/\A#{indent}/, '')}\n#{indent}end"
          end

          def rendered_case(rhs, indent, target)
            head = ["case", rhs.condition&.source].compact.join(" ")

            parts = rhs.when_branches.map { |w|
              conditions = w.conditions.map(&:source).join(", ")
              "#{indent}when #{conditions}\n#{indent}  #{target}#{w.body ? w.body.source : 'nil'}"
            }
            else_body = rhs.else_branch
            parts << "#{indent}else\n#{indent}  #{target}#{else_body ? else_body.source : 'nil'}"

            "#{head}\n#{parts.join("\n")}\n#{indent}end"
          end

          def conditional?(rhs)
            rhs.is_a?(RuboCop::AST::Node) &&
              CONDITIONAL_TYPES.include?(rhs.type)
          end

          # `keyword` is "" on a ternary — it has no `if` token to point at.
          def keyword(rhs)
            if rhs.type == :if
              if rhs.ternary?
                "ternary"
              else
                rhs.keyword
              end
            else
              "case"
            end
          end
      end
    end
  end
end
