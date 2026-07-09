---
layout: default
title: Examples
nav_order: 1
description: Runnable bots and bridges, each with a Docker Compose + Synapse stack.
---

# Examples

The [`examples/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples) directory holds complete, runnable services. Each brings its own `Dockerfile` and `docker-compose.yml` and stands up against a real [Synapse](https://github.com/element-hq/synapse) homeserver — not a mock — so you can invite the bot and watch it work.

## The shared Synapse stack

[`examples/synapse/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/synapse) is the base stack the other examples layer on: Synapse, a [FluffyChat](https://fluffychat.im/) web client to talk to it, and an Nginx reverse proxy. Start here to get a homeserver you can point a bot at.

## echo_bot

[`examples/echo_bot/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/echo_bot) — the canonical minimal application service. Two plain handlers: one auto-joins on invite (`m.room.member`), one echoes text back as a notice (`m.room.message`). This is the example the [Getting Started]({% link _getting_started/getting-started.md %}) guide builds toward, and the clearest illustration of the [handler duck-type]({% link _core_features/bots-and-handlers.md %}#plain-handlers).

## inbound_webhook_bot

[`examples/inbound_webhook_bot/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/inbound_webhook_bot) — shows off the fact that `Server` is a Grape API: it declares its **own** HTTP endpoint alongside the Matrix routes, so an external system can `POST` a webhook that the bot relays into a Matrix room. The pattern for wiring app-specific endpoints is covered in [Application Service]({% link _core_features/application-service.md %}#constructing-a-server).

## brute

[`examples/brute/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/brute) — an AI-agent bot. It passes an `ANTHROPIC_API_KEY` through to the container and answers messages with an LLM, demonstrating how a handler can call out to an external service (all fiber-concurrent) before replying.

## brute-steering

[`examples/brute-steering/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/brute-steering) — extends the brute agent with a steering check, showing a more involved handler pipeline around the same LLM loop.

## lindsey_and_dave

[`examples/lindsey_and_dave/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/lindsey_and_dave) — two bots in one stack, useful for watching services interact with each other rather than only with human users.

## Running an example

Each example directory is self-contained:

```sh
cd examples/echo_bot
docker compose up --build
```

Bring up the shared Synapse stack if the example expects it, open FluffyChat, and invite the bot's MXID (e.g. `@bot:localhost`) to a room. See each example's files for the exact compose wiring and any required environment variables (such as `ANTHROPIC_API_KEY` for the brute examples).
