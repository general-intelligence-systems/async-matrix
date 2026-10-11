# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# Reads the file under inspection with Prism, through ast-crispr-ruby-prism, instead of through the parser gem syntax tree RuboCop hands a cop.
#
# A cop which includes this does not use the `on_<type>` callbacks: those are driven by the parser gem tree, so a cop which reads a different tree walks it itself from `on_new_investigation`. What it gains is one parse of the file by the same Prism which runs the program, a uniform walk over every node, and the library's resolution of which comment documents which declaration.
#
# Offences are still reported against `Parser::Source::Range`, because that is what RuboCop and its correctors take. A Prism location and a RuboCop buffer measure the same source in bytes from the same origin, so a range is built from the offsets directly.
#
# The wrapper does not track parentage - `parent` and `next_sibling` are nil - so the walk records the parent of each node as it descends.
#
# Two kinds of leading comment are offered, because they are not interchangeable. `prism_leading_comments` is the run of lines touching a declaration, which is what documents it. `prism_owned_comments` is the wider span the library attributes to a statement, reaching back to whatever precedes it: for the first statement of a body that crosses the enclosing declaration and takes its comment too, so it answers where a comment sits rather than what a declaration says.

require "ast-crispr-ruby-prism"

module RuboCop
  module Cop
    module PrismSource
      # @returns [Ast::Crispr::DocumentContext] the file, parsed once however many times this is called.
      def prism_document
        self.prism_state.fetch(:document)
      end

      # @returns [Prism::Merge::FileAnalysis] what the library read the file as.
      def prism_analysis
        self.prism_document.ast
      end

      # @returns [TreeHaver::Backends::Prism::Node] the root of the tree, wrapped for a uniform walk.
      def prism_root
        self.prism_state.fetch(:root)
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
        ::Parser::Source::Range.new(processed_source.buffer, location.start_offset, location.end_offset)
      end

      # @returns [Parser::Source::Range] the whole of the given node.
      def prism_node_range(node)
        self.prism_range(node.location)
      end

      # @returns [String] the source of the given node.
      def prism_source(node)
        self.prism_document.location_slice(node.location)
      end

      # @returns [Array(Prism::InlineComment)] every comment in the file, in source order.
      def prism_comments
        self.prism_analysis.parse_result.comments
      end

      # The run of comment lines written directly above a declaration.
      #
      # @returns [Array(Prism::InlineComment)] the comments, in source order.
      def prism_leading_comments(node)
        self.prism_state.fetch(:leading)[node] ||= self.contiguous_above(node)
      end

      # Every comment the library reads the given statement as owning.
      #
      # @returns [Array(Prism::InlineComment)] the comments, in source order.
      def prism_owned_comments(node)
        self.prism_state.fetch(:owned)[node] ||= begin
          self.prism_document.comment_regions_for(node, region: :leading, owner_scope: :all_statements)
        rescue ::Ast::Crispr::Error
          []
        end
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
        document = ::Ast::Crispr::Ruby::Prism.document_context(
          content: source.buffer.source,
          source_label: source.path.to_s,
        )

        root = ::TreeHaver::Backends::Prism::Node.new(document.ast.parse_result.value, document.content)

        nodes = []
        parents = {}.compare_by_identity

        self.descend(root.inner_node, nil, nodes, parents)

        by_line = {}

        document.ast.parse_result.comments.each do |comment|
          by_line[comment.location.start_line] = comment
        end

        {
          document: document,
          root: root,
          nodes: nodes,
          parents: parents,
          by_line: by_line,
          leading: {}.compare_by_identity,
          owned: {}.compare_by_identity,
        }
      end

      # The tree, recorded flat with the parent of each node, since the wrapper does not say.
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
