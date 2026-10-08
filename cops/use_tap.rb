# frozen_string_literal: true

# Requires `tap` when a method opens by assigning a local variable and closes by
# returning that same variable:
#
#   def require_existing_column!                                    # NO
#     column = params[:id].to_s
#     unless connection.columns(@table).any? { |c| c.name == column }
#       render json: { error: "unknown column" }, status: :not_found
#     end
#     column
#   end
#
#   def require_existing_column!                                    # YES
#     params[:id].to_s.tap do |column|
#       unless connection.columns(@table).any? { |c| c.name == column }
#         render json: { error: "unknown column" }, status: :not_found
#       end
#     end
#   end
#
# The assign-work-return shape states the return value twice — once as the
# assignment target, once as a bare mention on the last line — and puts the two
# far enough apart that the trailing `column` reads as a stray expression.
# `tap` names the value once, scopes it to the block that works on it, and makes
# "the value flows through unchanged" structural rather than something you check
# by comparing the first and last lines.
#
# A body that REASSIGNS the variable is left alone: `tap` yields the original
# object and returns it, so that rewrite would change the result.
module RuboCop
  module Cop
    module Local
      class UseTap < Base
        MSG = "Assigning `%<name>s` and returning it at the end is `tap`; " \
              "write `<expression>.tap do |%<name>s| ... end`."

        # Every way a local can be written to after the opening assignment.
        REASSIGNMENTS = %i[lvasgn op_asgn or_asgn and_asgn masgn].freeze

        def on_def(node)
          check(node.body)
        end

        def on_defs(node)
          check(node.body)
        end

        private

          def check(body)
            if tap_shaped?(body)
              add_offense(body, message: format(MSG, name: assigned_name(body)))
            end
          end

          # First statement assigns a local; last statement is that same local,
          # read and nothing else.
          def tap_shaped?(body)
            body&.begin_type? &&
              body.children.size >= 2 &&
              body.children.first.lvasgn_type? &&
              returns_assigned?(body) &&
              !reassigned?(body)
          end

          def assigned_name(body)
            body.children.first.name
          end

          def returns_assigned?(body)
            last = body.children.last

            last.lvar_type? && last.children.first == assigned_name(body)
          end

          # `tap` yields the object the receiver evaluated to, so a body that
          # points the name at something else partway through is a different
          # program and must not be flagged.
          def reassigned?(body)
            name = assigned_name(body)

            body.children[1..-2].any? do |statement|
              statement.each_node(*REASSIGNMENTS).any? do |write|
                writes_name?(write, name)
              end
            end
          end

          def writes_name?(node, name)
            if node.masgn_type?
              node.assignments.any? { |target| target == name }
            else
              node.children.first == name
            end
          end
      end
    end
  end
end
