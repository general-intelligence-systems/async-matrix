# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Identifier
      # The grammar for an identifier with nothing to read.
      module Opaque
        # The unreserved characters of RFC 3986, and no more than two hundred and fifty five of them.
        PATTERN = /\A[0-9A-Za-z\-._~]{1,255}\z/

        class << self
          # @parameter string [String] the identifier to judge.
          # @returns [Boolean] whether it follows the grammar.
          def valid?(string)
            PATTERN.match?(string)
          end
        end
      end
    end
  end
end
