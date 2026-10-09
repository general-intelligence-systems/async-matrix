# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# The Matrix protocol layer: message formats, event schemas, and the rules for
# reading them. No HTTP, no sockets, no storage.
#
# The split follows the Socketry convention that `protocol-http` and
# `protocol-grpc` set: a protocol library owns the FORMAT and the state machine
# over it, and the `async-*` library binds that to IO. So an Event, a Content, an
# EncryptedMessage and the schemas that validate them live here, and the Client
# that fetches them lives in Async::Matrix.
#
# Practically, that means everything under this namespace can be unit tested
# with a Hash and no network, no homeserver, and — for EncryptedMessage — no
# crypto either.
module Protocol
  module Matrix
  end
end

Dir.glob("#{__dir__}/matrix/**/*.rb").sort.each do |path|
  require path
end
