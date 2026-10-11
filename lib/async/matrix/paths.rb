# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    # The Matrix client-server API is versioned per-endpoint rather than as a whole: most endpoints live under `/_matrix/client/v3`, but some (e.g. room summaries) are only available under `/_matrix/client/v1`, and media lives under `/_matrix/media/v3`.
    #
    # A {Client} is therefore rooted at the homeserver itself, and every path below is absolute, as an absolute path replaces the resource path rather than being appended to it.
    V1 = "/_matrix/client/v1"
    V3 = "/_matrix/client/v3"
    MEDIA_V3 = "/_matrix/media/v3"
    MEDIA_V1 = "/_matrix/media/v1"

    # The identity server API, which is a server of its own rather than a path on the homeserver.
    IDENTITY = "/_matrix/identity"
    IDENTITY_V2 = "/_matrix/identity/v2"

    # The push gateway API, which is run by whoever wrote the application being pushed to.
    PUSH_V1 = "/_matrix/push/v1"

    # The application service API, which a bridge serves and a homeserver calls.
    APP_V1 = "/_matrix/app/v1"

    # The server-server API, which is versioned per-endpoint as the client-server API is: an endpoint moves to `v2` on its own, so both are reachable at once.
    #
    # The keys a server publishes are not under `federation` at all, and neither is a policy server, which is a service a room names rather than a homeserver.
    FEDERATION_V1 = "/_matrix/federation/v1"
    FEDERATION_V2 = "/_matrix/federation/v2"
    KEY_V2 = "/_matrix/key/v2"
    POLICY_V1 = "/_matrix/policy/v1"
  end
end
