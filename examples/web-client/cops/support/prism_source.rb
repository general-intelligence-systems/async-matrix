# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Reads the file under inspection with Prism, which ships with Ruby, instead of through the parser gem syntax tree RuboCop hands a cop.
#
# A cop which includes this does not use the `on_<type>` callbacks: those are driven by the parser gem tree, so a cop which reads a different tree walks it itself from `on_new_investigation`. What it gains is one parse of the file by the same Prism which runs the program, and a uniform walk over every node.
#
# Offences are still reported against `Parser::Source::Range`, because that is what RuboCop and its correctors take. THE TWO DO NOT MEASURE THE SAME WAY: a Prism location counts BYTES and a `Parser::Source::Range` counts CHARACTERS, so a range built from `start_offset` is correct only until the first multibyte character in the file and silently wrong after it. Prism gives both, and `prism_range` takes the character pair.
#
# Prism does not track parentage - a node does not name the node it is written inside - so the walk records the parent of each node as it descends.

require "prism"

module RuboCop
  module Cop
    module PrismSource
      # @returns [Prism::ParseResult] the file, parsed once however many times this is called.
      def prism_result
        self.prism_state.fetch(:result)
      end

      # Every node in the file, outermost first, in source order.
      #
      # @returns [Array(Prism::Node)] the nodes.
      def prism_nodes
        self.prism_state.fetch(:nodes)
      end

      # @parameter classes [Array(Class)] the Prism node classes wanted.
      # @returns [Array(Prism::Node)] the nodes which are one of them.
      def prism_each(*classes)
        if classes.empty?
          self.prism_nodes
        else
          self.prism_nodes.select{|node| classes.any?{|klass| node.is_a?(klass)}}
        end
      end

      # @parameter node [Prism::Node] the node whose parent is wanted.
      # @returns [Prism::Node | nil] the node it is written inside, or nil at the root.
      def prism_parent(node)
        self.prism_state.fetch(:parents)[node]
      end

      # The nodes a node is written inside, innermost first.
      #
      # @returns [Array(Prism::Node)] the ancestors.
      def prism_ancestors(node)
        [].tap do |found|
          current = self.prism_parent(node)

          while current
            found << current
            current = self.prism_parent(current)
          end
        end
      end

      # @returns [Array(Prism::Node)] the nodes written directly inside the given node.
      def prism_children(node)
        node.compact_child_nodes
      end

      # Everything written inside the given node, at any depth, outermost first.
      #
      # @parameter classes [Array(Class)] the Prism node classes wanted, or none for all of them.
      # @returns [Array(Prism::Node)] the nodes.
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

      # Whether the given node contains a heredoc, whose content lives below the line it opens on.
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

      # The statements of a body, whether it holds one or many.
      #
      # @parameter body [Prism::StatementsNode | nil] the body of a method, module, or block.
      # @returns [Array(Prism::Node)] its statements, which is empty when there is no body.
      def prism_statements(body)
        if body.nil?
          []
        else
          body.body
        end
      end

      # A Prism location as the range RuboCop reports an offence against.
      #
      # @parameter location [Prism::Location] where the offence is.
      # @returns [Parser::Source::Range] the same place, measured for RuboCop.
      def prism_range(location)
        # CHARACTER OFFSETS, NOT `start_offset`. A `Parser::Source::Range` indexes the buffer by character and a Prism location counts bytes, so a range built from the byte pair lands further and further past where it should as the multibyte characters above it accumulate. A corrector handed such a range replaces the wrong text and writes a file which no longer parses.
        ::Parser::Source::Range.new(
          processed_source.buffer,
          location.start_character_offset,
          location.end_character_offset,
        )
      end

      # One range reaching from the start of the first location to the end of the last, for an offence over a run of statements rather than a single node.
      #
      # @returns [Parser::Source::Range] the span.
      def prism_span(first, last)
        ::Parser::Source::Range.new(
          processed_source.buffer,
          first.start_character_offset,
          last.end_character_offset,
        )
      end

      # @returns [Parser::Source::Range] the whole of the given node.
      def prism_node_range(node)
        self.prism_range(node.location)
      end

      # The column a node starts at, counted the way a Ruby String is indexed.
      #
      # @returns [Integer] the character column.
      def prism_column(node)
        # `Prism::Location#start_column` counts bytes, so indexing a line from `processed_source.lines` with it cuts in the wrong place once anything above or before it on that line is multibyte.
        node.location.start_character_column
      end

      # @returns [String] the source of the given node.
      def prism_source(node)
        node.location.slice
      end

      # @returns [Array(Prism::InlineComment)] every comment in the file, in source order.
      def prism_comments
        self.prism_result.comments
      end

      # The run of comment lines written directly above a declaration, which is what documents it.
      #
      # @returns [Array(Prism::InlineComment)] the comments, in source order.
      def prism_leading_comments(node)
        self.prism_state.fetch(:leading)[node] ||= self.contiguous_above(node)
      end

      # Every comment a declaration owns, which is the same run: a comment belongs to whatever it is written above.
      #
      # @returns [Array(Prism::InlineComment)] the comments, in source order.
      def prism_owned_comments(node)
        self.prism_leading_comments(node)
      end

      private

      # Everything read from the file, discarded when RuboCop moves to the next one.
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

      # The tree, recorded flat with the parent of each node, since Prism does not say.
      def descend(node, parent, nodes, parents)
        nodes << node
        parents[node] = parent

        node.compact_child_nodes.each do |child|
          self.descend(child, node, nodes, parents)
        end
      end

      # The run of comment lines ending on the line above the node, stopping at the first gap.
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
