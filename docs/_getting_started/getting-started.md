---
layout: default
title: Getting Started
nav_order: 1
description: Install async-matrix, point a Client at a homeserver, and make your first authenticated call.
---

# Getting Started

This guide installs async-matrix and makes authenticated calls against a Matrix homeserver from inside an async reactor.

If what you want is the *server* side — a service your homeserver `PUT`s transactions at, dispatching events to handlers — that is [async-matrix-bridge](https://general-intelligence-systems.github.io/async-matrix-bridge/), which depends on this gem. Everything below still applies: the bridge hands you the same `Client`.

## Requirements

- Ruby >= 3.3
- A Matrix homeserver and an access token for it

async-matrix ships a native Rust extension for [end-to-end encryption]({% link _advanced/encryption.md %}). `gem install` serves a precompiled gem for common platforms; on anything else it compiles at install time and needs a Rust toolchain.

## Installation

```ruby
# Gemfile
gem "async-matrix"
```

```sh
bundle install
```

## Configuration

A `Config` is a YAML file (or plain hash) exposed through dot notation. `Client` reads exactly two fields from it — `homeserver.address` and `appservice.as_token` — and ignores the rest:

```yaml
# config/appservice.yml
homeserver:
  address: "http://synapse:8008"
  domain: "localhost"

appservice:
  as_token: "long-random-string-A"
  bot:
    username: "bot"
```

```ruby
require "async/matrix"

config = Async::Matrix::Config.load("config/appservice.yml")

config.homeserver.address   # => "http://synapse:8008"
config.bot_mxid             # => "@bot:localhost"
```

`Config` validates nothing — it vivifies whatever you hand it. A subclass adds validation by overriding `.validate!`, which is how async-matrix-bridge layers the mautrix bridgev2 JSON Schema suite on top without reimplementing the loading.

Building one inline works too, which is handy in specs:

```ruby
config = Async::Matrix::Config.new(
  "homeserver" => {"address" => "http://localhost:8008", "domain" => "localhost"},
  "appservice" => {"as_token" => "token", "bot" => {"username" => "bot"}}
)
```

## Making calls

Every `Client` method is a fiber operation, so calls belong inside an async reactor:

```ruby
client = Async::Matrix::Client.new(config)

Async do
  client.join_room("!room:example.org")
  client.send_text("!room:example.org", "Hello world")
  client.send_notice("!room:example.org", "A notice")
  client.send_html("!room:example.org", "<b>bold</b>")
end
```

Concurrency is what fibers buy you — these run in parallel over a pooled connection, not one after another:

```ruby
Async do
  rooms.map { |id| Async { client.send_notice(id, "broadcast") } }.each(&:wait)
end
```

The client retries 502/503/504 with exponential backoff and full jitter, honours `Retry-After` on 429, and caps response bodies while streaming them. See the [Client]({% link _core_features/client.md %}) page for the per-request knobs and the full method list.

## Beyond the convenience methods

The convenience methods cover the common cases. For anything else, `client.api` builds a path by method chaining and validates it against the official Matrix Client-Server OpenAPI documents bundled in the gem:

```ruby
Async do
  client.api.account.whoami.get
  client.api.createRoom.post(name: "Pub", preset: "public_chat")
  client.api.rooms("!room:example.org").messages.get(dir: "b", limit: 10)
end
```

Binary routes (upload, download, thumbnail) are detected and dispatched to the [media client]({% link _advanced/media.md %}) automatically.

## Events

Events parse into `Async::Matrix::Event`, with dot-accessible content and optional validation against the upstream Matrix event schemas:

```ruby
event = Async::Matrix::Schema.parse(raw_hash)

event.type              # => "m.room.message"
event.sender            # => "@alice:example.org"
event.content.body      # => "hello"
event.valid?            # => true
event.valid!            # => true, or raises Schema::ValidationError
```

Next: the [Client]({% link _core_features/client.md %}) in full, or [events and schema validation]({% link _core_features/events-and-schemas.md %}).
