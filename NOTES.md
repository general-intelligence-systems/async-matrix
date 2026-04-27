# Project Notes

## What Is This

A Ruby framework for building Matrix Application Services, with an ambitious secondary goal of scaffolding a full Matrix homeserver implementation. Built on the `async` ecosystem (Falcon web server, async-http) targeting Ruby 3.4 and Rack 3. Licensed Apache 2.0 (Copyright 2026 General Intelligence Systems).

Very early stage -- 6 commits, sole author (Nathan Kidd), single `main` branch. GitHub remote: `general-intelligence-systems/async-matrix`.

---

## Project Layout

```
lib/
  async.rb                          # Module declaration: Async::Matrix
  async/matrix/
    endpoint.rb                     # Well-known discovery (most complete)
    notifier.rb                     # Async event bus for /sync long-polling
    client.rb                       # HTTP/2 client stub
    server.rb                       # HTTP/2 server stub
    connection.rb                   # HTTP/2 connection stub
    stream.rb                       # HTTP/2 stream stub

examples/
  synapse/                          # Minimal echo bot (working appservice bridge)
  morph_suit/                       # Echo bot + full Matrix API scaffold + DB schema

Gemfile / Gemfile.lock              # Root dependencies
flake.nix / flake.lock              # Nix dev environment
.envrc                              # direnv -> `use flake`
LICENSE                             # Apache 2.0
config/                             # Empty
files/                              # Empty (runtime artifacts)
refs/                               # Gitignored reference repos (async-http, protocol-http, synapse)
```

No README, no gemspec, no Rakefile, no tests, no CI/CD.

---

## Core Library (`lib/async/matrix/`)

All classes live under `Async::Matrix`.

**`Endpoint`** -- The most fleshed-out class. Extends `Async::HTTP::Protocol::HTTP2::Endpoint` with a `self.discover(domain)` class method that resolves homeserver URLs via `/.well-known/matrix/client` (per spec). Falls back to `https://domain` if well-known is unavailable.

**`Notifier`** -- A waitable event bus built on `Async::Condition`. Designed for `/sync` long-polling patterns. `#signal` wakes all waiting fibers; `#wait(timeout:, &block)` blocks until the block returns truthy or timeout expires.

**`Client`, `Server`, `Connection`, `Stream`** -- Empty subclasses of their `Async::HTTP::Protocol::HTTP2` counterparts. Placeholder stubs for future Matrix-specific protocol extensions.

---

## Echo Bot Example (`examples/synapse/`)

A working Matrix Application Service that auto-joins rooms and echoes messages. This is the reference for how the appservice bridge pattern works.

### Boot sequence

```
config.ru (entry point, loaded by Falcon)
  -> Config.load("config/appservice.yml")   # tokens, homeserver URL, bot MXID
  -> Client.new(config)                      # outbound Matrix CS API client
  -> Dispatcher.new                          # event router
  -> register handlers (Invite, Message)
  -> Server.new(config, dispatcher)          # Rack app for inbound AS API
  -> run Server
```

### Inbound flow (Homeserver -> Bot)

1. Synapse pushes events to `PUT /_matrix/app/v1/transactions/{txnId}`
2. `Server#call` validates `hs_token` (constant-time compare), parses JSON
3. `TransactionStore` checks for duplicate txn IDs (in-memory LRU, capacity 1024)
4. `Dispatcher#dispatch_transaction` wraps body in `Matrix::ApplicationService::Models::Transaction`, iterates `events` + `ephemeral`, routes each event by `type` to matching handlers

### Outbound flow (Bot -> Homeserver)

`Client` wraps `Async::HTTP::Internet` with `Bearer {as_token}` auth. Methods: `send_text`, `send_html`, `send_notice`, `join_room`, `leave_room`, `set_display_name`, `whoami`. All use `/_matrix/client/v3` paths.

### Handlers

- **`Handlers::Invite`** -- On `m.room.member` with `membership: invite` targeting the bot, calls `client.join_room`
- **`Handlers::Message`** -- On `m.room.message` with `msgtype: m.text`, echoes back as `m.notice` (skips self-messages)

### Server endpoints

| Method | Path | Behavior |
|--------|------|----------|
| PUT | `/_matrix/app/v1/transactions/{txnId}` | Receives events, dispatches |
| GET | `/_matrix/app/v1/users/{userId}` | Returns 200 (user exists) |
| GET | `/_matrix/app/v1/rooms/{roomAlias}` | Returns 404 |
| POST | `/_matrix/app/v1/ping` | Health check, returns `{}` |

### Running it

```sh
docker compose up    # from examples/synapse/
```

Starts Synapse on :8008/:8448 and the bot on :9292. Registration file at `config/registration.yml` defines bot identity (`@bot:localhost`), tokens, and namespaces.

---

## Morph Suit Example (`examples/morph_suit/`)

Same echo bot base as above, plus two major additions:

### Grape API Scaffold (`api/`)

~85 endpoint files stubbing the **entire Matrix specification** (v1.18). All endpoints return `TODO: implement` or placeholder responses.

| API Surface | Path Prefix | Files |
|-------------|-------------|-------|
| Client-Server v3 | `/_matrix/client/v3` | ~25 (login, sync, rooms, profile, keys, push, devices, etc.) |
| Client-Server v1 | `/_matrix/client/v1` | ~8 (login, register, media, appservice, etc.) |
| Federation v1 | `/_matrix/federation/v1` | ~18 (send, event, backfill, make_join, state, etc.) |
| Federation v2 | `/_matrix/federation/v2` | 3 (send_join, send_leave, invite) |
| App Service | `/_matrix/app/v1` | 5 (transactions, ping, users, rooms, thirdparty) |
| Identity v2 | `/_matrix/identity/v2` | ~12 (lookup, 3pid, validate, etc.) |
| Key v2 | `/_matrix/key/v2` | 2 (server, query) |
| Media | `/_matrix/media/v1,v3` | 2 (create, upload) |
| Push Gateway | `/_matrix/push/v1` | 1 (notify) |
| Policy | `/_matrix/policy/v1` | 1 (sign) |
| Well-Known | `/.well-known/matrix` | 4 (client, server, support, policy_server) |

Entry point: `api/api.rb` (`MatrixApi::API < Base`) mounts all sub-APIs.
Base class: `api/base.rb` provides auth helpers and error handling via Grape.

### Sequel Database Schema (`migrations/` + `models/`)

134 Sequel migrations replicating the **entire Synapse database schema**. 134 corresponding Sequel model files. Database connection via `db.rb` using `DATABASE_URL` (PostgreSQL).

Key models with relationships:
- `User` (PK: `name`) -- has_many `access_tokens`, `devices`, `refresh_tokens`, `account_data`
- `Room` (PK: `room_id`) -- has_many `events`, `current_state_events`, `batch_events`
- `AccessToken` -- belongs_to `user`, `refresh_token`
- `Device` (composite PK) -- belongs_to `user`
- `RoomMembership` -- belongs_to `room`, `user`, `event`

Tables cover: rooms, users, events, state, federation, E2EE keys, push rules, media, device lists, presence, receipts, user directory, and more (~80+ tables).

Note: Grape and Sequel are **not in the root Gemfile** -- morph_suit has its own dependency expectations.

---

## Dependencies

### Root Gemfile

| Gem | Version | Purpose |
|-----|---------|---------|
| falcon | ~> 0.47 | Async web server (serves the Rack app) |
| async | ~> 2.0 | Fiber-based concurrency framework |
| async-http | ~> 0.69 | Async HTTP client/server |
| rack | ~> 3.0 | Web server interface |
| logger | - | Standard logging |
| scampi | ~> 0.1.7 | Colorized terminal output |

### Dev Environment

- **Nix flake** provides Ruby 3.4, Node.js, libyaml, openssl, imagemagick, helm
- **direnv** auto-activates via `.envrc` (`use flake`)
- Gems install to local `.gem/` directory

---

## Observations

**Missing `lib/matrix.rb`** -- Both example `config.ru` files do `require_relative "../../lib/matrix"` but no such file exists. This file would presumably define `Matrix.logger`, `Matrix::ApplicationService::Models::Transaction`, `Matrix::ApplicationService::Models::ErrorResponse`, and `Matrix::Errors::*` -- all of which are referenced by the example code but never defined anywhere in the repo.

**Undefined classes referenced by examples:**
- `Matrix::ApplicationService::Models::Transaction` (wraps inbound event payloads)
- `Matrix::ApplicationService::Models::ErrorResponse` (wraps homeserver error responses)
- `Matrix::Errors::NotFound`, `Matrix::Errors::BadJson`, `Matrix::Errors::Auth`, `Matrix::Errors::Homeserver`
- `Matrix.logger`

**All Grape endpoints are stubs** -- The morph_suit API scaffold has the routing and structure but every handler body is `# TODO: implement` or returns a placeholder.

**HTTP/2 subclasses are empty** -- `Client`, `Server`, `Connection`, `Stream` in `lib/` inherit from async-http but add no behavior yet.

**No tests** -- No spec/, test/, or any test files exist anywhere.

**No gemspec** -- The library isn't packaged as a gem yet.

**No CI/CD** -- No GitHub Actions, no linting config (.rubocop.yml), no automated checks.

**Duplicate examples** -- `examples/synapse/` and `examples/morph_suit/` share identical files for the echo bot portion (config.ru, server.rb, client.rb, config.rb, dispatcher.rb, transaction_store.rb, handlers/, Dockerfile, docker-compose.yml, config files). No shared code extraction yet.

**Grape + Sequel not in root Gemfile** -- The morph_suit example depends on gems not declared in the project's Gemfile.

**`refs/` directory** -- Contains cloned source repos (async-http, protocol-http, protocol-http2, synapse) for reference. Gitignored.
