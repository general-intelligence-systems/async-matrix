# frozen_string_literal: true

# Requires a call with more than `MaxArguments` arguments to break every
# argument onto its own line:
#
#   walk(rest, current_dir, controller_segments, dynamic_pairs + [[param_name, segment]], last_dir_name)
#
#   walk(                                                           # YES
#     rest,
#     current_dir,
#     controller_segments,
#     dynamic_pairs + [[param_name, segment]],
#     last_dir_name,
#   )
#
# The built-in Layout/FirstMethodArgumentLineBreak and
# Layout/MultilineMethodArgumentLineBreaks only decide WHERE a call breaks once
# it is already multi-line; a five-argument call on one long line satisfies both
# of them, and the only thing standing between it and the right margin is
# Layout/LineLength — which "fixes" it by wrapping wherever column 120 happens
# to land, mid-argument. This cop makes the argument count, not the column, the
# thing that forces the break.
#
# Calls written without parentheses are left alone: there is no bracket pair to
# hang the arguments off, so the rewrite would have to add one.
module RuboCop
  module Cop
    module Local
      class MultilineMethodArguments < Base
        extend AutoCorrector

        MSG = "Call takes %<count>d arguments; put each one on its own line."

        def on_send(node)
          if too_many_on_one_line?(node)
            add_offense(node, message: format(MSG, count: node.arguments.count)) do |corrector|
              break_arguments(corrector, node)
            end
          end
        end

        alias on_csend on_send
        alias on_super on_send

        private

          def too_many_on_one_line?(node)
            node.parenthesized? &&
              node.arguments.count > max_arguments &&
              !every_argument_on_its_own_line?(node)
          end

          # The first argument must clear the line that opened the call, and no
          # two arguments may share a line.
          def every_argument_on_its_own_line?(node)
            lines = node.arguments.map { |argument| argument.source_range.first_line }

            lines.first > node.loc.begin.line && lines == lines.uniq
          end

          def break_arguments(corrector, node)
            if safe_to_break?(node)
              corrector.insert_after(node.loc.begin, "\n")

              node.arguments.each_cons(2) do |left, right|
                corrector.replace(between(left, right), ",\n")
              end

              corrector.insert_before(node.loc.end, "\n")
            end
          end

          # A heredoc's body lives below the line the call sits on, so moving
          # the call's own line breaks around would reorder it. Comments between
          # arguments occupy the same ranges this rewrite overwrites, and would
          # be deleted. Both are left for a human.
          def safe_to_break?(node)
            node.arguments.none? { |argument| contains_heredoc?(argument) } &&
              node.arguments.each_cons(2).none? do |left, right|
                between(left, right).source.include?("#")
              end
          end

          def contains_heredoc?(node)
            node.each_node(:str, :dstr, :xstr).any?(&:heredoc?)
          end

          # The comma-and-whitespace run separating two arguments.
          def between(left, right)
            Parser::Source::Range.new(
              processed_source.buffer,
              left.source_range.end_pos,
              right.source_range.begin_pos,
            )
          end

          def max_arguments
            cop_config.fetch("MaxArguments", 3)
          end
      end
    end
  end
end
