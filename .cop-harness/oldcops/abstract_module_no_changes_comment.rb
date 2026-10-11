# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "rubocop"

module RuboCop
  module Cop
    module AsyncMatrix
      # Checks that an empty version layer says which version it stands for.
      #
      # @example
      #   # bad - empty, and says nothing
      #   module V1_19
      #   end
      #
      # @example
      #   # bad - the comment names the wrong version
      #   # No changes in v1.18.
      #   module V1_19
      #   end
      #
      # @example
      #   # good
      #   # No changes in v1.19.
      #   module V1_19
      #   end
      #
      # @example
      #   # good - it changed something, so it speaks for itself
      #   # v1.19 added the thing.
      #   module V1_19
      #     def thing
      #     end
      #   end
      class AbstractModuleNoChangesComment < Base
        extend AutoCorrector

        MSG = "An empty version layer must say so: `%<expected>s`."

        def on_module(node)
          if version = self.version_for(node)
            if node.body.nil?
              expected = format(COMMENT, version: version)
              comment = processed_source.comment_at_line(node.first_line - 1)
              if comment and comment.text == expected
                nil
              else
                add_offense(node.identifier, message: format(MSG, expected: expected)) do |corrector|
                  if comment
                    corrector.replace(comment.source_range, expected)
                  else
                    indentation = " " * node.loc.keyword.column

                    corrector.insert_before(node.loc.keyword, "#{expected}\n#{indentation}")
                  end
                end
              end
            else
              nil
            end
          else
            nil
          end
        end

        private

        COMMENT = "# No changes in %<version>s."

        # The version a layer stands for, if it is one: `V1_19` is `v1.19`.
        #
        # @returns [String | nil] the version, or nil if this is not a version layer.
        def version_for(node)
          match = /\AV(\d+)_(\d+)\z/.match(node.identifier.short_name.to_s)

          if match
            if self.abstract?(node)
              "v#{match[1]}.#{match[2]}"
            else
              nil
            end
          else
            nil
          end
        end

        # Only layers below `Abstract` are version layers, so that a module which merely looks like one elsewhere is left alone.
        def abstract?(node)
          node.each_ancestor(:module).any? do |ancestor|
            ancestor.identifier.short_name == :Abstract
          end
        end
      end
    end
  end
end
