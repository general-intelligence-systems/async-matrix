# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Checks the structure of a comment, which decode parses into three parts: the summary, the annotations, and the summary belonging to each annotation.
#
# @example
#   # Connect to the given endpoint, returning the HTTP client and reference.   <- summary
#   # @parameter endpoint [Endpoint] used to connect to the remote system.      <- annotation
#   # @returns [Tuple(Client, Reference)] the client and reference.
#
# Four things are checked, each measured against how async-rest, async-discord and async-ollama document themselves:
#
# A paragraph occupies one line. None of the 99 summary paragraphs in those three projects is wrapped, and async-rest's run to 544 characters.
#
# A summary is short, and no longer than the code it describes earns. Across 76 documented methods the median summary is 4 to 9 words whatever the length of the method, so the allowance starts at ten words and grows by three per line of body, to a ceiling of thirty.
#
# A module's summary is ten words or fewer. The only commented module in async-rest is exactly ten.
#
# A documented method says what it takes and returns. A summary with no annotations describes the method in prose and leaves the signature undocumented, which is what annotations are for. A method with no comment at all is not this cop's business: that is documentation coverage, which decode reports on separately.
#
# Nothing here is corrected automatically. A comment which breaks these rules has to be rewritten rather than reflowed, and a correction which only moved the words around would hide that.
#
# Each check is configured on its own, because they are not all worth applying everywhere:
#
# @example
#   Local/CommentStructure:
#     Annotations:
#       Include:
#         - "lib/**/*.rb"
#     Length:
#       Exclude:
#         - "bin/**/*"
#     Wrapping:
#       Enabled: true
#
# A check with no `Include` runs everywhere; given one, it runs only where a path matches. `Exclude` then removes paths from whatever is left. `Annotations` defaults to `lib` alone: a script in `bin` and a case in `test` have no interface for anyone else to call, so annotating them documents nothing.
#
# What a declaration says is read from the run of comment lines touching it. Where an offence is reported is read from the wider span the library attributes to the declaration, less any magic comment, because decode reports a part's position within that span rather than the line it came from.

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

        # Each check, and the paths it applies to when the configuration names none.
        CHECKS = {
          "Wrapping" => nil,
          "Length" => nil,
          "Annotations" => ["lib/**/*.rb"].freeze,
        }.freeze

        GLOB = File::FNM_PATHNAME | File::FNM_EXTGLOB

        HEADER = /\A#\s*(frozen_string_literal:|Released under|Copyright,|!)/

        # What a Ruby file says to the interpreter rather than to a reader.
        MAGIC = /\A#\s*(frozen_string_literal:|encoding:|coding:|warn_indent:|shareable_constant_value:|!|-\*-)/

        TERMINAL = [".", ":", "?", "!"].freeze

        # Multi-line content is the point of these, so their summaries are left alone.
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

        # Whether a check applies to the file being inspected.
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

        # @parameter default [Boolean] what an absent or empty list of patterns means.
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

        # The comment which documents a declaration, as the parts decode reads it as.
        def parts_of(node)
          comments = self.documenting(node)

          if comments.empty?
            nil
          else
            self.parse(comments)
          end
        end

        # The comment above a declaration, without the file's own header.
        def documenting(node)
          self.prism_leading_comments(node).reject{|comment| self.prism_source(comment).match?(HEADER)}
        end

        # Every comment the declaration owns, which is what the parts are indexed against.
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

        # Consecutive comment lines: a block is what documents one thing, so a wrap can only happen inside one.
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

        # decode consumes the lines it parses and does not report where they came from, so they are handed over through something which records what it gave away.
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

        # The comment without its `#`, keeping the indentation which tells decode what is nested.
        def text_of(comment)
          self.prism_source(comment).sub(/\A#\s?/, "")
        end

        # Where to report a summary which is too long: the comment line it starts on, or the declaration itself when the summary cannot be traced back to one.
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

        # What decode shifts lines off, which remembers them.
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
