---
layout: default
title: Discord Bridge
nav_order: 4
description: The Sequel-backed Discord bridge database layer, loaded on demand and kept out of the default require path.
---

# Discord Bridge

async-matrix includes the data layer for a Matrix ↔ Discord bridge under `Async::Matrix::Bridge::Discord`. It is deliberately **not** loaded by `require "async/matrix"`: the bridge pulls in [Sequel](https://sequel.jeremyevans.net/) and opens a placeholder database at load time, so the core SDK stays free of that dependency. Require it explicitly when you need it:

```ruby
require "async/matrix/bridge/discord/db"
```

Requiring that one file loads the whole subsystem — the Sequel schema placeholder, the connection helper, and every model class — so `DB.connect` can bind them all.

## Connecting

`DB.connect` reads the bridge config's `database` section, establishes the Sequel connection, runs the migrations under `bridge/discord/db/migrations`, and wires every model to the database:

```ruby
require "async/matrix/bridge/discord/db"

Async::Matrix::Bridge::Discord::DB.connect(config)
```

## The model layer

The bridge maps Discord and Matrix entities to each other with these Sequel models:

| Model | Represents |
|---|---|
| `User` | a Matrix user linked to the bridge |
| `Puppet` | a Discord user's Matrix "puppet" (ghost) account |
| `Guild` | a Discord guild (server) |
| `Portal` | a bridged room ↔ channel pairing |
| `Message` | a message mapped across both sides (for edits, replies, redactions) |
| `Reaction` | an emoji reaction mapped across both sides |
| `File` | tracked media/attachments |

The message and reaction tables are what let the bridge translate edits, deletions, and reactions in both directions — each row ties a Matrix event ID to its Discord counterpart.

## Why it's opt-in

Keeping the bridge behind an explicit `require` is a deliberate boundary: a plain bot or application service never pays for Sequel, and only a real bridge deployment loads the database machinery. The rest of async-matrix — [server]({% link _core_features/application-service.md %}), [client]({% link _core_features/client.md %}), [events]({% link _core_features/events-and-schemas.md %}) — is identical whether or not the bridge is present.
