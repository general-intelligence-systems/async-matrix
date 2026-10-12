# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      # Requires a method whose body is a single expression to use the endless method form.
      #
      # @example
      #   # bad
      #   def event_type
      #     "m.room.message"
      #   end
      #   # good
      #   def event_type = "m.room.message"
      class SingleLineMethodsForEvents < Base
        include PrismSource
        extend AutoCorrector

        MSG = "A method whose body is one expression must use the endless form: `def name = expression`."

        # Expressions which can follow ` = ` unchanged. Anything with its own `end`, or with lower precedence than the assignment, is left as a block: what it would parse as is not what it says as a body.
        ACCEPTED_BODIES = [
          ::Prism::ArrayNode,
          ::Prism::CallNode,
          ::Prism::ClassVariableReadNode,
          ::Prism::ConstantPathNode,
          ::Prism::ConstantReadNode,
          ::Prism::FalseNode,
          ::Prism::FloatNode,
          ::Prism::GlobalVariableReadNode,
          ::Prism::HashNode,
          ::Prism::ImaginaryNode,
          ::Prism::InstanceVariableReadNode,
          ::Prism::IntegerNode,
          ::Prism::InterpolatedStringNode,
          ::Prism::InterpolatedSymbolNode,
          ::Prism::InterpolatedXStringNode,
          ::Prism::LocalVariableReadNode,
          ::Prism::NilNode,
          ::Prism::RangeNode,
          ::Prism::RationalNode,
          ::Prism::RegularExpressionNode,
          ::Prism::SelfNode,
          ::Prism::StringNode,
          ::Prism::SymbolNode,
          ::Prism::TrueNode,
          ::Prism::XStringNode,
        ].freeze

        def on_new_investigation
          self.prism_each(::Prism::DefNode).each do |node|
            if self.rewriteable?(node)
              self.report(node)
            end
          end
        end

        private

        # The one expression a method's body is, when that is what it is.
        def sole_expression(node)
          statements = self.prism_statements(node.body)

          if statements.size == 1
            statements.first
          else
            nil
          end
        end

        # A method is rewritten only when it is not endless, not a setter, and has one non-heredoc body expression on one line.
        def rewriteable?(node)
          body = self.sole_expression(node)

          !self.endless?(node) &&
            !self.setter?(node.name) &&
            !body.nil? &&
            ACCEPTED_BODIES.any?{|klass| body.is_a?(klass)} &&
            self.single_line?(node, body) &&
            !self.prism_heredoc?(body)
        end

        # An endless method is written with `=` rather than a body closed by `end`.
        def endless?(node)
          !node.equal_loc.nil?
        end

        # The offense is reported either way; the correction is withheld when a comment sits inside the method, since replacing the method would take the comment with it.
        def report(node)
          range = self.prism_node_range(node)

          if self.comment?(node)
            add_offense(range)
          else
            add_offense(range) do |corrector|
              corrector.replace(range, self.endless_form(node))
            end
          end
        end

        # `def foo=(value)` and `def []=(key, value)` have no endless form.
        def setter?(name)
          name == :[]= || /\A[a-zA-Z_]\w*=\z/.match?(name.to_s)
        end

        # The body on one line, and the signature on one line too, so that the rewritten method is still a single line.
        def single_line?(node, body)
          body.location.start_line == body.location.end_line &&
            !self.signature_source(node).include?("\n")
        end

        # The source of the signature, e.g. `def build(**fields)`, without the gap before the body.
        def signature_source(node)
          source = processed_source.buffer.source

          # byteslice, because every offset here is one of Prism's and those count bytes, where `String#[]` counts characters.
          source.byteslice(node.location.start_offset...self.signature_end(node))
        end

        def signature_end(node)
          ending = node.name_loc.end_offset

          if parameters = node.parameters
            [ending, parameters.location.end_offset].max
          else
            ending
          end
        end

        def comment?(node)
          self.prism_comments.any? do |comment|
            (node.location.start_line..node.location.end_line).cover?(comment.location.start_line)
          end
        end

        def endless_form(node)
          "#{self.signature(node)} = #{self.prism_source(self.sole_expression(node))}"
        end

        def signature(node)
          "#{self.receiver_prefix(node)}#{node.name}#{self.arguments_suffix(node)}"
        end

        def receiver_prefix(node)
          if node.receiver
            "def #{self.prism_source(node.receiver)}."
          else
            "def "
          end
        end

        # Bare arguments are ambiguous before ` = `; parenthesize them.
        def arguments_suffix(node)
          parameters = node.parameters

          if parameters.nil?
            ""
          else
            "(#{self.prism_source(parameters)})"
          end
        end
      end
    end
  end
end
