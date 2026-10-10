# frozen_string_literal: true

# Checks the structure of a comment, which decode parses into three parts: the summary, the
# annotations, and the summary belonging to each annotation.
#
#   # A resource is an abstract reference to some named entity.   <- summary
#   #
#   # Any information that can be named can be a resource.        <- summary, second paragraph
#   # @parameter endpoint [Endpoint] used to connect.             <- annotation + its summary
#
# A paragraph of either kind occupies exactly one line, however long that line becomes. In
# async-rest the summary paragraphs run to 544 characters and none of them is wrapped; the same
# holds for async-discord. Wrapping is what this cop bans, because a paragraph split over several
# comment lines reads as several paragraphs to anything which parses it, and because re-wrapping
# after an edit produces a diff which touches lines nobody changed.
#
# The parsing is decode's own - `Decode::Language::Ruby::Generic::TAGS` - so an annotation is
# whatever decode recognises as one. A directive it does not recognise is not an annotation and is
# read as summary text, which is the behaviour to want here: `@param` is not a tag, so a line
# carrying it is prose that happens to begin with an at sign.

require "decode/language/ruby/generic"

module RuboCop
  module Cop
    module Local
      class CommentStructure < Base
        extend AutoCorrector

        MSG_SUMMARY = "Do not wrap a summary paragraph; a paragraph is one line, however long."

        MSG_ANNOTATION = "Do not wrap the summary of `@%<directive>s`; an annotation's summary is one line."

        TAGS = Decode::Language::Ruby::Generic::TAGS

        # The lines which say what the file is rather than what the code does.
        HEADER = /\A#\s*(frozen_string_literal:|Released under|Copyright,|!)/

        TERMINAL = [".", ":", "?", "!"].freeze

        # Multi-line content is the point of these, so their summaries are left alone.
        FREEFORM = [Decode::Comment::Example].freeze

        def on_new_investigation
          self.blocks.each do |block|
            self.check(block)
          end
        end

        private

        # Consecutive comment lines, as decode would be given them: a block is what documents one
        # thing, so a wrap can only happen inside one.
        def blocks
          found = []
          current = []

          processed_source.comments.each do |comment|
            if comment.text.match?(HEADER) or comment.text.start_with?("# rubocop:")
              next
            end

            if current.empty? or comment.loc.line == current.last.loc.line + 1
              current << comment
            else
              found << current
              current = [comment]
            end
          end

          found << current unless current.empty?

          found
        end

        # Walk the nodes decode parses out of the block, alongside the lines each one consumed, so
        # that an offence can be reported where it is rather than where the block starts.
        def check(block)
          nodes = self.parse(block)

          nodes.each_with_index do |(node, lines), index|
            case node
            when Decode::Comment::Text
              following = nodes[index + 1]&.first

              if following.is_a?(Decode::Comment::Text) and !self.terminated?(node.line)
                self.report(lines.first, block, MSG_SUMMARY)
              end
            else
              unless FREEFORM.include?(node.class)
                summary = lines.drop(1).reject{|line| self.annotation?(line.last)}

                if summary.size > 1
                  message = format(MSG_ANNOTATION, directive: node.directive)

                  self.report(summary.first, block, message)
                end
              end
            end
          end
        end

        # decode consumes the lines it parses, so they are handed over through something which
        # records what it gave away: that is what maps a node back onto its source.
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
          comment.text.sub(/\A#\s?/, "")
        end

        def annotation?(text)
          text.strip.start_with?("@")
        end

        def terminated?(line)
          text = line.strip

          text.empty? or TERMINAL.any?{|mark| text.end_with?(mark)}
        end

        # Join the wrapped line onto the one which follows it, which is the whole correction.
        def report(entry, block, message)
          comment = block[entry.first]
          following = block[entry.first + 1]

          add_offense(comment, message: message) do |corrector|
            if following
              gap = Parser::Source::Range.new(
                processed_source.buffer,
                comment.loc.expression.end_pos,
                following.loc.expression.begin_pos + self.hash_width(following),
              )

              corrector.replace(gap, " ")
            end
          end
        end

        # How much of the following comment is the `#` and the space after it.
        def hash_width(comment)
          comment.text[/\A#\s?/].length
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
