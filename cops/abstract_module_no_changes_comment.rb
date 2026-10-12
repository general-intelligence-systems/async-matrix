# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "support/prism_source"

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
        include PrismSource

        extend AutoCorrector

        MSG = "An empty version layer must say so: `%<expected>s`."

        def on_new_investigation
          self.prism_each(::Prism::ModuleNode).each do |node|
            self.check(node)
          end
        end

        private

        COMMENT = "# No changes in %<version>s."

        def check(node)
          if version = self.version_for(node)
            if node.body.nil?
              expected = format(COMMENT, version: version)
              comment = self.prism_leading_comments(node).last

              if comment and self.prism_source(comment) == expected
                nil
              else
                range = self.prism_node_range(node.constant_path)

                add_offense(range, message: format(MSG, expected: expected)) do |corrector|
                  if comment
                    corrector.replace(self.prism_range(comment.location), expected)
                  else
                    keyword = node.module_keyword_loc
                    indentation = " " * keyword.start_character_column

                    corrector.insert_before(self.prism_range(keyword), "#{expected}\n#{indentation}")
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

        # The version a layer stands for, if it is one: `V1_19` is `v1.19`.
        #
        # @returns [String | nil] the version, or nil if this is not a version layer.
        def version_for(node)
          match = /\AV(\d+)_(\d+)\z/.match(node.name.to_s)

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
          self.prism_ancestors(node).any? do |ancestor|
            ancestor.is_a?(::Prism::ModuleNode) && ancestor.name == :Abstract
          end
        end
      end
    end
  end
end
