---
layout: default
title: async-matrix
nav_order: 1
description: 'Async-native Matrix protocol primitives for Ruby. Fibers, not threads — built on the Socketry ecosystem (async, async-http, Falcon).'
permalink: /
---

# async-matrix

Async-native [Matrix](https://matrix.org) protocol primitives for Ruby. Built on the [Socketry](https://github.com/socketry) ecosystem (`async`, `async-http`, [Falcon](https://github.com/socketry/falcon)) — no threads, no callbacks, just fibers.
{: .fs-6 .fw-300 }

<div class="hero-actions">
  <a href="{% link _getting_started/getting-started.md %}" class="btn btn-primary fs-5 mb-4 mb-md-0 mr-2">Get started</a>
  <a href="https://github.com/general-intelligence-systems/async-matrix" class="btn fs-5 mb-4 mb-md-0 mr-2">GitHub</a>
</div>

async-matrix is the Matrix protocol layer: a Client-Server API client whose method chains validate against the official OpenAPI documents, events that validate against the upstream event JSON schemas, media upload and download, and Olm/Megolm end-to-end encryption through a native binding. Every HTTP call is a fiber operation over a pooled connection, so thousands of concurrent calls to a homeserver cost you connection-pool slots, not threads.

Writing the *server* side of a bridge or bot — receiving transactions from a homeserver and dispatching events to handlers — is [async-matrix-bridge](https://general-intelligence-systems.github.io/async-matrix-bridge/), which builds on this gem.

## Quick start

```ruby
require "async/matrix"

config = Async::Matrix::Config.load("config/appservice.yml")
client = Async::Matrix::Client.new(config)

Async do
  client.join_room("!room:example.org")
  client.send_notice("!room:example.org", "Hello from a fiber")
end
```

```sh
gem install async-matrix
```

## What's here

- **Core Features** — the [Client]({% link _core_features/client.md %}) and its schema-validated API chain, and [events and schema validation]({% link _core_features/events-and-schemas.md %}).
- **Advanced** — [end-to-end encryption]({% link _advanced/encryption.md %}) (Olm/Megolm via a native binding) and [media]({% link _advanced/media.md %}) upload/download.

## Design principles

1. **Async all the way down.** Every HTTP call is a fiber operation on `Async::HTTP::Internet` with fiber-safe connection pooling. No thread pools, no callback soup.
2. **Retries are the library's job.** Exponential backoff with full jitter for 502/503/504, `Retry-After` parsing for 429, and response size limits enforced while streaming.
3. **Specs are the source of truth.** The API chain validates against the official Matrix Client-Server OpenAPI documents, and events validate against the upstream event JSON schemas — both bundled into the gem.
