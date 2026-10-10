# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "rubocop"

module RuboCop
  module Cop
    module Local
      # Requires a method whose body is a single expression to use the endless method form.
      #
      # A method which returns one expression does not need `def ... end`: the endless form says the
      # same thing on the line it is defined on, so the body sits beside the name rather than a level
      # below it. Only a method which can be rewritten without changing what it means is flagged: its
      # signature has to be on one line, and its body a single expression on one line.
      #
      # The check is confined to the event classes by `Include` in `.rubocop.yml`, since that is where
      # the house style is settled.
      #
      # @example
      #   # bad
      #   def event_type
      #     "m.room.message"
      #   end
      #
      #   # good
      #   def event_type = "m.room.message"
      class SingleLineMethodsForEvents < Base
        extend AutoCorrector

        MSG = "A method whose body is one expression must use the endless form: `def name = expression`."

        # Expressions which can follow ` = ` unchanged. Anything with its own `end`, or with lower
        # precedence than the assignment, is left as a block: what it would parse as is not what it
        # says as a body.
        ACCEPTED_BODIES = %i[
          array const csend cvar dstr dsym erange false float gvar hash int irange ivar lvar nil
          rational regexp self send str sym true xstr
        ].freeze

        def on_def(node)
          check(node)
        end
        alias on_defs on_def

        private

        def check(node)
          return if node.endless?
          return if setter?(node.method_name)
          return if node.body.nil?
          return unless ACCEPTED_BODIES.include?(node.body.type)
          return unless single_line?(node)
          return if heredoc?(node.body)

          if comment?(node)
            add_offense(node)
          else
            add_offense(node) do |corrector|
              corrector.replace(node, endless_form(node))
            end
          end
        end

        # `def foo=(value)` and `def []=(key, value)` have no endless form.
        def setter?(name)
          name == :[]= || /\A[a-zA-Z_]\w*=\z/.match?(name.to_s)
        end

        # The body on one line, and the signature on one line too, so that the rewritten method is
        # still a single line.
        def single_line?(node)
          body = node.body

          body.first_line == body.last_line && !signature_source(node).include?("\n")
        end

        # The source of the signature, e.g. `def build(**fields)`, without the gap before the body.
        def signature_source(node)
          source = processed_source.buffer.source

          source[node.source_range.begin_pos...signature_end(node)]
        end

        def signature_end(node)
          ending = node.loc.name.end_pos

          if (arguments = node.arguments) && (range = arguments.source_range)
            [ending, range.end_pos].max
          else
            ending
          end
        end

        # A heredoc's content sits on the lines below its opening token, outside `body.source`, so
        # rewriting it would separate the body from the text it contains.
        def heredoc?(body)
          body.each_node(:str, :dstr, :xstr).any?(&:heredoc?)
        end

        def comment?(node)
          processed_source.comments.any? do |comment|
            (node.first_line..node.last_line).cover?(comment.loc.line)
          end
        end

        def endless_form(node)
          "#{endless_signature(node)} = #{node.body.source}"
        end

        def endless_signature(node)
          name = if node.receiver
            "def #{node.receiver.source}.#{node.method_name}"
          else
            "def #{node.method_name}"
          end

          arguments = node.arguments&.source.to_s

          if arguments.empty?
            name
          elsif arguments.start_with?("(")
            "#{name}#{arguments}"
          else
            # Bare arguments are ambiguous before ` = `; parenthesize them.
            "#{name}(#{arguments})"
          end
        end
      end
    end
  end
end
