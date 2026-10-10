# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # The Matrix client-server API is versioned per-endpoint rather than as a whole: most endpoints
    # live under `/_matrix/client/v3`, but some (e.g. room summaries) are only available under
    # `/_matrix/client/v1`, and media lives under `/_matrix/media/v3`.
    #
    # A {Client} is therefore rooted at the homeserver itself, and every path below is absolute, as
    # an absolute path replaces the resource path rather than being appended to it.
    V1 = "/_matrix/client/v1"
    V3 = "/_matrix/client/v3"
    MEDIA_V3 = "/_matrix/media/v3"
  end
end
