# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "e2ee/canonical_json"
require_relative "e2ee/crypto"
require_relative "e2ee/device"
require_relative "e2ee/devices"
require_relative "e2ee/machine"
require_relative "e2ee/plaintext"
require_relative "e2ee/store"

module Async
  module Matrix
    # Encryption, for the clients which need it.
    module E2EE
    end
  end
end
