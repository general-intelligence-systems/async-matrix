---
layout: default
title: async-matrix
nav_order: 1
description: 'An async-native Matrix Application Service SDK for Ruby. Fibers, not threads — built on the Socketry ecosystem (async, async-http, Falcon).'
permalink: /
---

# async-matrix

An async-native [Matrix](https://matrix.org) Application Service SDK for Ruby. Built on the [Socketry](https://github.com/socketry) ecosystem (`async`, `async-http`, [Falcon](https://github.com/socketry/falcon)) — no threads, no callbacks, just fibers.
{: .fs-6 .fw-300 }

<div class="hero-actions">
  <a href="{% link _getting_started/getting-started.md %}" class="btn btn-primary fs-5 mb-4 mb-md-0 mr-2">Get started</a>
  <a href="https://github.com/general-intelligence-systems/async-matrix" class="btn fs-5 mb-4 mb-md-0 mr-2">GitHub</a>
</div>

async-matrix implements the [Matrix Application Service API](https://spec.matrix.org/latest/application-service-api/): the server side of a bridge or bot. Your homeserver `PUT`s transactions of events at your service; async-matrix authenticates them, deduplicates them, and dispatches each event to the handlers you register. The whole stack runs on fibers, so thousands of concurrent HTTP calls back to the homeserver cost you connection-pool slots, not threads.

## Quick start

```ruby
# config.ru
require "async/matrix"

config = Async::Matrix::ApplicationService::Config.load("config/appservice.yml")
client = Async::Matrix::Client.new(config)

bot = Async::Matrix::ApplicationService::Bot.new(client) do
  on "m.room.member" do |event|
    join_room(event.room_id) if event.content.membership == "invite"
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    send_notice event.room_id, "Echo: #{event.content.body}"
  end
end

app = Async::Matrix::ApplicationService::Server.new(
  hs_token: config.appservice.hs_token,
  client:   client
) do
  dispatch bot
end

run app
```

```sh
falcon serve --bind http://0.0.0.0:9292
```

That's a complete echo bot. The `Server` wraps a [Grape](https://github.com/ruby-grape/grape) API with the Matrix wire-protocol routes mixed in; `dispatch` registers a bot or plain handler; Falcon serves it. Head to [Getting Started]({% link _getting_started/getting-started.md %}) for a full walkthrough with a homeserver.

## What's here

- **Core Features** — the [Application Service server]({% link _core_features/application-service.md %}) and event flow, [bots and handlers]({% link _core_features/bots-and-handlers.md %}) (the `dispatch` DSL and the handler duck-type), the [Client]({% link _core_features/client.md %}) and its schema-validated API chain, and [events and schema validation]({% link _core_features/events-and-schemas.md %}).
- **Advanced** — [configuration]({% link _advanced/configuration.md %}) with JSON-Schema validation, [end-to-end encryption]({% link _advanced/encryption.md %}) (Olm/Megolm via a native binding), [media]({% link _advanced/media.md %}) upload/download, and the [Discord bridge]({% link _advanced/discord-bridge.md %}).
- **Examples** — [runnable bots and bridges]({% link _examples/examples.md %}), each with a Docker Compose + Synapse stack.

## Design principles

1. **Async all the way down.** Every HTTP call is a fiber operation on `Async::HTTP::Internet` with fiber-safe connection pooling. No thread pools, no callback soup.
2. **The homeserver is untrusted input.** Transactions are authenticated with a constant-time token compare and deduplicated by transaction ID before any handler runs. One handler raising never takes down the rest.
3. **Specs are the source of truth.** The API chain validates against the official Matrix Client-Server OpenAPI documents, and events validate against the upstream event JSON schemas — both bundled into the gem.
