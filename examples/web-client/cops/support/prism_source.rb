# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require "prism"

module RuboCop
  module Cop
    module PrismSource
      def prism_result
        self.prism_state.fetch(:result)
      end

      def prism_nodes
        self.prism_state.fetch(:nodes)
      end

      def prism_each(*classes)
        if classes.empty?
          self.prism_nodes
        else
          self.prism_nodes.select{|node| classes.any?{|klass| node.is_a?(klass)}}
        end
      end

      def prism_parent(node)
        self.prism_state.fetch(:parents)[node]
      end

      def prism_ancestors(node)
        [].tap do |found|
          current = self.prism_parent(node)

          while current
            found << current
            current = self.prism_parent(current)
          end
        end
      end

      def prism_children(node)
        node.compact_child_nodes
      end

      def prism_descendants(node, *classes)
        [].tap do |found|
          pending = node.compact_child_nodes.dup

          until pending.empty?
            current = pending.shift

            if classes.empty? or classes.any?{|klass| current.is_a?(klass)}
              found << current
            end

            pending.concat(current.compact_child_nodes)
          end
        end
      end

      def prism_heredoc?(node)
        [node].concat(self.prism_descendants(node)).any? do |current|
          case current
          when ::Prism::StringNode, ::Prism::InterpolatedStringNode,
               ::Prism::XStringNode, ::Prism::InterpolatedXStringNode
            current.heredoc?
          else
            false
          end
        end
      end

      def prism_statements(body)
        if body.nil?
          []
        else
          body.body
        end
      end

      def prism_range(location)
        ::Parser::Source::Range.new(
          processed_source.buffer,
          location.start_character_offset,
          location.end_character_offset,
        )
      end

      def prism_span(first, last)
        ::Parser::Source::Range.new(
          processed_source.buffer,
          first.start_character_offset,
          last.end_character_offset,
        )
      end

      def prism_node_range(node)
        self.prism_range(node.location)
      end

      def prism_column(node)
        node.location.start_character_column
      end

      def prism_source(node)
        node.location.slice
      end

      def prism_comments
        self.prism_result.comments
      end

      def prism_leading_comments(node)
        self.prism_state.fetch(:leading)[node] ||= self.contiguous_above(node)
      end

      def prism_owned_comments(node)
        self.prism_leading_comments(node)
      end

      private

      def prism_state
        source = processed_source

        unless @prism_state and @prism_source.equal?(source)
          @prism_source = source
          @prism_state = self.read(source)
        end

        @prism_state
      end

      def read(source)
        result = ::Prism.parse(source.buffer.source)

        nodes = []
        parents = {}.compare_by_identity

        self.descend(result.value, nil, nodes, parents)

        by_line = {}

        result.comments.each do |comment|
          by_line[comment.location.start_line] = comment
        end

        {
          result: result,
          nodes: nodes,
          parents: parents,
          by_line: by_line,
          leading: {}.compare_by_identity,
        }
      end

      def descend(node, parent, nodes, parents)
        nodes << node
        parents[node] = parent

        node.compact_child_nodes.each do |child|
          self.descend(child, node, nodes, parents)
        end
      end

      def contiguous_above(node)
        by_line = self.prism_state.fetch(:by_line)
        found = []
        line = node.location.start_line - 1

        while comment = by_line[line]
          found.unshift(comment)
          line -= 1
        end

        found
      end
    end
  end
end
