# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.


require "decode/language/ruby/generic"

require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class CommentStructure < Base
        include PrismSource

        MSG_WRAPPED_SUMMARY = "Do not wrap a summary paragraph: a paragraph is one line, however long."

        MSG_WRAPPED_ANNOTATION = "Do not wrap the summary of `@%<directive>s`: an annotation's summary is one line."

        MSG_TOO_LONG = "This summary is %<words>d words; %<allowed>d is the most %<subject>s may have."

        MSG_NO_ANNOTATIONS = "This method is described in prose but its parameters and return value are not: document them with annotations, or say nothing."

        TAGS = Decode::Language::Ruby::Generic::TAGS

        CHECKS = {
          "Wrapping" => nil,
          "Length" => nil,
          "Annotations" => ["lib/**/*.rb"].freeze,
        }.freeze

        GLOB = File::FNM_PATHNAME | File::FNM_EXTGLOB

        HEADER = /\A#\s*(frozen_string_literal:|Released under|Copyright,|!)/

        MAGIC = /\A#\s*(frozen_string_literal:|encoding:|coding:|warn_indent:|shareable_constant_value:|!|-\*-)/

        TERMINAL = [".", ":", "?", "!"].freeze

        FREEFORM = [Decode::Comment::Example].freeze

        def on_new_investigation
          if self.applies?("Wrapping")
            self.blocks.each do |block|
              self.check_wrapping(block)
            end
          end

          if self.applies?("Length")
            self.prism_each(::Prism::ModuleNode).each do |node|
              self.check_summary(node, "a module summary", self.cop_config.fetch("ModuleWords", 10))
            end

            self.prism_each(::Prism::ClassNode).each do |node|
              self.check_summary(node, "a class summary", self.cop_config.fetch("MaximumWords", 30))
            end
          end

          self.prism_each(::Prism::DefNode).each do |node|
            self.check_method(node)
          end
        end

        private

        def applies?(check)
          configuration = self.cop_config[check] || {}

          if configuration["Enabled"] == false
            false
          else
            path = ::RuboCop::PathUtil.relative_path(processed_source.file_path.to_s)

            included = configuration["Include"] || CHECKS.fetch(check)
            excluded = configuration["Exclude"] || []

            self.matches?(path, included, true) and !self.matches?(path, excluded, false)
          end
        end

        def matches?(path, patterns, default)
          if patterns.nil? or patterns.empty?
            default
          else
            patterns.any?{|pattern| File.fnmatch?(pattern, path, GLOB)}
          end
        end

        def check_method(node)
          lines = node.location.end_line - node.location.start_line + 1
          base = self.cop_config.fetch("BaseWords", 10)
          per_line = self.cop_config.fetch("WordsPerLine", 3)
          ceiling = self.cop_config.fetch("MaximumWords", 30)

          allowed = [base + (per_line * lines), ceiling].min

          if self.applies?("Length")
            self.check_summary(node, "a summary of #{lines} #{lines == 1 ? "line" : "lines"} of code", allowed)
          end

          if self.applies?("Annotations")
            self.check_annotations(node)
          end
        end

        def parts_of(node)
          comments = self.documenting(node)

          if comments.empty?
            nil
          else
            self.parse(comments)
          end
        end

        def documenting(node)
          self.prism_leading_comments(node).reject{|comment| self.prism_source(comment).match?(HEADER)}
        end

        def owned(node)
          self.prism_owned_comments(node).drop_while{|comment| self.prism_source(comment).match?(MAGIC)}
        end

        def check_summary(node, subject, allowed)
          parts = self.parts_of(node)

          if parts
            summary = parts.map(&:first).grep(Decode::Comment::Text)
            words = summary.sum{|text| text.line.split.size}

            if words > allowed
              message = format(MSG_TOO_LONG, words: words, allowed: allowed, subject: subject)

              add_offense(self.summary_range(node, parts, summary.first), message: message)
            end
          end
        end

        def check_annotations(node)
          parts = self.parts_of(node)

          if parts and parts.any?{|part, _| part.is_a?(Decode::Comment::Text)}
            annotations = parts.map(&:first).reject{|part| part.is_a?(Decode::Comment::Text)}

            if annotations.empty?
              add_offense(self.prism_range(node.name_loc), message: MSG_NO_ANNOTATIONS)
            end
          end
        end

        def blocks
          [].tap do |found|
            current = []

            self.prism_comments.each do |comment|
              text = self.prism_source(comment)

              if text.match?(HEADER) or text.start_with?("# rubocop:")
                next
              end

              if current.empty? or comment.location.start_line == current.last.location.start_line + 1
                current << comment
              else
                found << current
                current = [comment]
              end
            end

            unless current.empty?
              found << current
            end
          end
        end

        def check_wrapping(block)
          nodes = self.parse(block)

          nodes.each_with_index do |(node, lines), index|
            if node.is_a?(Decode::Comment::Text)
              following = nodes[index + 1]&.first

              if following.is_a?(Decode::Comment::Text) and !self.terminated?(node.line)
                add_offense(self.prism_range(block[lines.first.first].location), message: MSG_WRAPPED_SUMMARY)
              end
            elsif !FREEFORM.include?(node.class)
              summary = lines.drop(1).reject{|line| line.last.strip.start_with?("@")}

              if summary.size > 1
                message = format(MSG_WRAPPED_ANNOTATION, directive: node.directive)

                add_offense(self.prism_range(block[summary.first.first].location), message: message)
              end
            end
          end
        end

        def parse(block)
          source = Consumable.new(block.each_with_index.map{|comment, index| [index, self.text_of(comment)]})
          nodes = []
          cursor = 0

          TAGS.parse(source) do |node|
            if node
              nodes << [node, source.log[cursor..]]
              cursor = source.log.size
            end
          end

          nodes
        end

        def text_of(comment)
          self.prism_source(comment).sub(/\A#\s?/, "")
        end

        def summary_range(node, parts, text)
          comments = self.owned(node)
          entry = text && parts.find{|part, _| part.equal?(text)}

          if entry and comments[entry.last.first.first]
            self.prism_range(comments[entry.last.first.first].location)
          else
            self.prism_node_range(node)
          end
        end

        def terminated?(line)
          text = line.strip

          text.empty? or TERMINAL.any?{|mark| text.end_with?(mark)}
        end

        class Consumable
          def initialize(entries)
            @entries = entries
            @log = []
          end

          attr :log

          def first = @entries.first&.last

          def shift
            entry = @entries.shift

            if entry
              @log << entry
              entry.last
            end
          end

          def empty? = @entries.empty?
        end
      end
    end
  end
end
