---
layout: default
title: Getting Started
nav_order: 1
description: Install async-matrix, register an application service with your homeserver, and run your first bot on Falcon.
---

# Getting Started

This guide installs async-matrix, wires a bot up to a homeserver via the Application Service API, and runs it on Falcon.

## Requirements

- Ruby >= 3.3
- A Matrix homeserver you can register an application service with (e.g. [Synapse](https://github.com/element-hq/synapse))

## Installation

```ruby
# Gemfile
gem "async-matrix"
gem "falcon"      # the async Rack server you'll run the service on
```

```sh
bundle install
```

## 1. Register the service with your homeserver

An application service is trusted code that runs *alongside* your homeserver. The homeserver needs a `registration.yml` describing your service and the two shared secrets that authenticate traffic in each direction:

```yaml
# registration.yml — hand this to your homeserver
id: "echo"
url: "http://echo:9292"                     # where the homeserver reaches your service
as_token: "long-random-string-A"            # your service -> homeserver
hs_token: "long-random-string-B"            # homeserver -> your service
sender_localpart: "bot"
namespaces:
  users:
    - exclusive: true
      regex: "@bot:.*"
```

Point your homeserver at it (Synapse: add the path to `app_service_config_files` in `homeserver.yaml`) and restart.

{: .note }
The `as_token` authenticates *your* calls to the homeserver; the `hs_token` authenticates the homeserver's transactions to *you*. async-matrix uses a constant-time compare on the `hs_token` for every inbound transaction.

## 2. Configure the service

async-matrix loads its own YAML config, validated against a JSON-Schema suite (see [Configuration]({% link _advanced/configuration.md %})):

```yaml
# config/appservice.yml
homeserver:
  address: "http://synapse:8008"
  domain: "localhost"

appservice:
  as_token: "long-random-string-A"
  hs_token: "long-random-string-B"
  bot:
    username: "bot"
```

## 3. Write the bot

The [`Bot` DSL]({% link _core_features/bots-and-handlers.md %}) pairs a `Client` with event handlers. Blocks run in a context that exposes helpers like `send_notice` and `join_room`, so you rarely touch the client directly:

```ruby
# config.ru
require "async/matrix"

config = Async::Matrix::ApplicationService::Config.load("config/appservice.yml")
client = Async::Matrix::Client.new(config)

bot = Async::Matrix::ApplicationService::Bot.new(client) do
  # Auto-join whenever someone invites the bot.
  on "m.room.member" do |event|
    join_room(event.room_id) if event.content.membership == "invite"
  end

  # Echo text messages back as a notice, skipping the bot's own messages.
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

`dispatch` accepts a `Bot` or any plain handler object — see [Bots and Handlers]({% link _core_features/bots-and-handlers.md %}) for the duck-type contract and filter options.

## 4. Serve it

`Server` is a Rack app, so any async-capable Rack server works. Use Falcon:

```sh
falcon serve --bind http://0.0.0.0:9292
```

Override the config path at runtime with an environment variable:

```sh
APPSERVICE_CONFIG=/etc/bot/appservice.yml falcon serve --bind http://0.0.0.0:9292
```

Invite `@bot:localhost` to a room and say hello — it echoes back.

## What happens on each transaction

1. The homeserver `PUT`s a batch of events to `/_matrix/app/v1/transactions/{txnId}`.
2. The `Server` authenticates the request (constant-time `hs_token` compare) and rejects anything unauthenticated with `403 M_FORBIDDEN`.
3. The transaction ID is checked against an in-memory store; already-seen IDs return `200` immediately without re-dispatching — the endpoint is idempotent.
4. Each event is wrapped and routed to every handler whose `#event_types` matches. Handlers run independently; an exception in one is logged and the rest still run.
5. Your handler calls back to the homeserver through the [`Client`]({% link _core_features/client.md %}) — every call a fiber operation over a pooled connection.

Next: the [Application Service internals]({% link _core_features/application-service.md %}), or jump to a complete [Docker Compose example]({% link _examples/examples.md %}).
