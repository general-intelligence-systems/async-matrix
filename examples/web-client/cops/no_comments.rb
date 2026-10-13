# frozen_string_literal: true

require_relative "support/prism_source"

module RuboCop
  module Cop
    module Local
      class NoComments < Base
        include PrismSource
        include RangeHelp
        extend AutoCorrector

        MSG = "Do not write comments."

        HEADER = /\A#\s*(frozen_string_literal:|Released under|Copyright,|!)/

        def on_new_investigation
          self.prism_comments.each do |comment|
            unless self.prism_source(comment).match?(HEADER)
              self.report(comment)
            end
          end
        end

        private

        def report(comment)
          range = self.prism_node_range(comment)

          add_offense(range) do |corrector|
            if self.own_line?(comment)
              corrector.remove(range_by_whole_lines(range, include_final_newline: true))
            end
          end
        end

        def own_line?(comment)
          line = processed_source.lines[comment.location.start_line - 1].to_s

          line[0...self.prism_column(comment)].strip.empty?
        end
      end
    end
  end
end
