# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require_relative "subject"

# What signing a federation request costs, which is the whole path rather than one part of it.
#
# Reading the body back so it can be signed and still sent, building the object which is signed, canonicalising it, signing it, and formatting the header. Paid once per request a server makes to another server, so it is the federation counterpart of what events/wrap measures for a client.

MIDDLEWARE = Subject.middleware

run_benchmark do
  # `authorization` is private, and the public `call` would need somewhere to send the request:
  MIDDLEWARE.send(:authorization, Subject.request)
end
