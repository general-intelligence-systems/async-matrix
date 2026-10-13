# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class NoConditionalAssignment < Base
        include PrismSource
        extend AutoCorrector

        MSG = "Do not assign a `%<keyword>s` expression to a variable; " \
              "assign inside each branch of the %<keyword>s."

        WRITES = [
          ::Prism::ClassVariableAndWriteNode,
          ::Prism::ClassVariableOperatorWriteNode,
          ::Prism::ClassVariableOrWriteNode,
          ::Prism::ClassVariableWriteNode,
          ::Prism::ConstantAndWriteNode,
          ::Prism::ConstantOperatorWriteNode,
          ::Prism::ConstantOrWriteNode,
          ::Prism::ConstantPathAndWriteNode,
          ::Prism::ConstantPathOperatorWriteNode,
          ::Prism::ConstantPathOrWriteNode,
          ::Prism::ConstantPathWriteNode,
          ::Prism::ConstantWriteNode,
          ::Prism::GlobalVariableAndWriteNode,
          ::Prism::GlobalVariableOperatorWriteNode,
          ::Prism::GlobalVariableOrWriteNode,
          ::Prism::GlobalVariableWriteNode,
          ::Prism::InstanceVariableAndWriteNode,
          ::Prism::InstanceVariableOperatorWriteNode,
          ::Prism::InstanceVariableOrWriteNode,
          ::Prism::InstanceVariableWriteNode,
          ::Prism::LocalVariableAndWriteNode,
          ::Prism::LocalVariableOperatorWriteNode,
          ::Prism::LocalVariableOrWriteNode,
          ::Prism::LocalVariableWriteNode,
          ::Prism::MultiWriteNode,
        ].freeze

        SIMPLE = [
          ::Prism::ClassVariableWriteNode,
          ::Prism::ConstantWriteNode,
          ::Prism::GlobalVariableWriteNode,
          ::Prism::InstanceVariableWriteNode,
          ::Prism::LocalVariableWriteNode,
        ].freeze

        CONDITIONALS = [
          ::Prism::CaseMatchNode,
          ::Prism::CaseNode,
          ::Prism::IfNode,
          ::Prism::UnlessNode,
        ].freeze

        def on_new_investigation
          self.prism_each(*WRITES).each do |node|
            self.check(node, node.value)
          end

          self.prism_each(::Prism::CallNode).each do |node|
            if self.assignment_method?(node)
              self.check(node, self.last_argument(node))
            end
          end
        end

        private

        def check(node, rhs)
          if self.conditional?(rhs)
            range = self.prism_node_range(node)

            add_offense(range, message: format(MSG, keyword: self.keyword(rhs))) do |corrector|
              if self.safe_to_push_inside?(node, rhs)
                corrector.replace(range, self.pushed_inside(node, rhs))
              end
            end
          end
        end

        def conditional?(rhs)
          !rhs.nil? && CONDITIONALS.any?{|klass| rhs.is_a?(klass)}
        end

        def assignment_method?(node)
          node.name.to_s.end_with?("=") && !node.name.to_s.end_with?("==") && !node.arguments.nil?
        end

        def last_argument(node)
          node.arguments&.arguments&.last
        end

        def safe_to_push_inside?(node, rhs)
          !rhs.is_a?(::Prism::CaseMatchNode) &&
            self.own_line?(node) &&
            self.simple_target?(node) &&
            !self.prism_heredoc?(node) &&
            self.branches(rhs).all?{|_condition, body| body.nil? || !self.prism_source(body).include?("\n")}
        end

        def simple_target?(node)
          if SIMPLE.any?{|klass| node.is_a?(klass)}
            true
          elsif node.is_a?(::Prism::CallNode)
            receiver = node.receiver

            node.arguments&.arguments&.one? &&
              receiver.is_a?(::Prism::CallNode) &&
              (receiver.arguments.nil? || receiver.arguments.arguments.empty?)
          else
            false
          end
        end

        def own_line?(node)
          line = processed_source.lines[node.location.start_line - 1].to_s

          line[0...self.prism_column(node)].strip.empty?
        end

        def target_source(node)
          if node.is_a?(::Prism::CallNode)
            "#{self.prism_source(node.receiver)}.#{node.name.to_s.chomp("=")} = "
          else
            "#{node.name} = "
          end
        end

        def branches(rhs)
          if rhs.is_a?(::Prism::CaseNode) || rhs.is_a?(::Prism::CaseMatchNode)
            self.case_branches(rhs)
          else
            self.if_branches(rhs)
          end
        end

        def if_branches(node, acc = [])
          acc << [self.prism_source(node.predicate), node.statements]

          following = self.else_branch(node)

          if following.is_a?(::Prism::IfNode) && !self.ternary?(following)
            self.if_branches(following, acc)
          else
            acc << [nil, following.is_a?(::Prism::ElseNode) ? following.statements : following]
          end

          acc
        end

        def case_branches(node)
          node.conditions.map{|when_node| [when_node, when_node.statements]} +
            [[nil, node.else_clause&.statements]]
        end

        def else_branch(node)
          if node.is_a?(::Prism::UnlessNode)
            node.else_clause
          else
            node.subsequent
          end
        end

        def pushed_inside(node, rhs)
          indent = " " * self.prism_column(node)
          target = self.target_source(node)

          if rhs.is_a?(::Prism::CaseNode)
            self.rendered_case(rhs, indent, target)
          else
            self.rendered_if(rhs, indent, target)
          end
        end

        def rendered_if(rhs, indent, target)
          parts = self.if_branches(rhs).each_with_index.map{|(condition, body), index|
            if condition.nil?
              header = "#{indent}else"
            elsif index.zero?
              header = "#{indent}if #{condition}"
            else
              header = "#{indent}elsif #{condition}"
            end

            "#{header}\n#{indent}  #{target}#{body ? self.prism_source(body) : "nil"}"
          }

          "#{parts.join("\n").sub(/\A#{indent}/, "")}\n#{indent}end"
        end

        def rendered_case(rhs, indent, target)
          head = ["case", rhs.predicate && self.prism_source(rhs.predicate)].compact.join(" ")

          parts = rhs.conditions.map{|when_node|
            conditions = when_node.conditions.map{|condition| self.prism_source(condition)}.join(", ")

            "#{indent}when #{conditions}\n#{indent}  #{target}#{when_node.statements ? self.prism_source(when_node.statements) : "nil"}"
          }
          else_body = rhs.else_clause&.statements
          parts << "#{indent}else\n#{indent}  #{target}#{else_body ? self.prism_source(else_body) : "nil"}"

          "#{head}\n#{parts.join("\n")}\n#{indent}end"
        end

        def ternary?(node)
          node.is_a?(::Prism::IfNode) && node.if_keyword_loc.nil?
        end

        def keyword(rhs)
          if rhs.is_a?(::Prism::IfNode)
            if self.ternary?(rhs)
              "ternary"
            else
              "if"
            end
          elsif rhs.is_a?(::Prism::UnlessNode)
            "unless"
          else
            "case"
          end
        end
      end
    end
  end
end
