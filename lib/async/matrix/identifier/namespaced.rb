# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Identifier
      # The grammar for an identifier nobody sees, added in v1.2.
      module Namespaced
        # A name begins with a letter, and carries letters, digits, hyphens, underscores and dots.
        PATTERN = /\A[a-z][a-z0-9\-_.]{0,254}\z/

        # The prefix the specification keeps for itself.
        RESERVED = "m."

        class << self
          # @parameter string [String] the identifier to judge.
          # @returns [Boolean] whether it follows the grammar.
          def valid?(string)
            PATTERN.match?(string)
          end

          # Whether the specification has this name, rather than leaving it to an implementation.
          #
          # @parameter string [String] the identifier to judge.
          # @returns [Boolean] whether it is reserved.
          def reserved?(string)
            string.to_s.start_with?(RESERVED)
          end
        end
      end
    end
  end
end
