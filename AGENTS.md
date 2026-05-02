# AGENTS.md — async-matrix

## Ruby repos

Your bin directory should contain `bin/test` and `bin/rubocop`.
If there isn't a `.rubocop.yml`, then add the following `.rubocop.yml` spec that disables all specs and only enables a few. 

```yaml
AllCops:
  DisabledByDefault: true

  RubyInterpreters:
    - ruby

  Include:
    - '**/*.rb'
    - '.pryrc'

  Exclude:
    <% Dir.glob("#{__dir__}/*").grep_v(%r{#{__dir__}\/(app|lib)}).each do |dir| %>
    - <%= dir %>/**/*
    <% end %>
    - 'lib/templates/**/*'

Layout/IndentationConsistency:
  Enabled: true
  EnforcedStyle: indented_internal_methods

Layout/BlockEndNewline:
  Enabled: true

Layout/BeginEndAlignment:
  Enabled: true
  EnforcedStyleAlignWith: start_of_line

Layout/ElseAlignment:
  Enabled: true

Layout/DefEndAlignment:
  Enabled: true
  EnforcedStyleAlignWith: def

Layout/EmptyLinesAroundAccessModifier:
  Enabled: true
  EnforcedStyle: around
```

## Specifications

**IMPORTANT:** Before implementing any feature, consult the specifications in `specs/README.md`.

- **Assume NOT implemented.** Many specs describe planned features that may not yet exist in the codebase.
- **Check the codebase first.** Before concluding something is or isn't implemented, search the actual code. Specs describe intent; code describes reality.
- **Use specs as guidance.** When implementing a feature, follow the design patterns, types, and architecture defined in the relevant spec.
- **Spec index:** `specs/README.md` lists all specifications organized by category (core, LLM, security, etc.).

## Project Overview

**async-matrix** is an async-native Matrix Application Service SDK for Ruby (gem: `async-matrix`, version 1.0.0). Built entirely on the Socketry ecosystem (`async`, `async-http`, Falcon) using fibers. Licensed Apache 2.0, authored by Nathan Kidd at General Intelligence Systems.

Requires Ruby >= 3.3. Uses Nix flake for dev environment (`.envrc` + `flake.nix`).

## Commands

### Run tests

```bash
bin/test
# or directly:
CONSOLE_LEVEL=fatal bundle exec scampi
```

Tests use **scampi** (inline co-located test framework). There is no `test/` or `spec/` directory — tests live as `test do ... end` blocks **at the bottom of every source file**. Scampi discovers them via ripgrep.

To run a single file's tests, use scampi's file filter:

```bash
CONSOLE_LEVEL=fatal bundle exec scampi lib/async/matrix/client.rb
```

### Lint

No `.rubocop.yml` exists yet. One needs to be created per the Ruby repos section above, along with `bin/rubocop`.

### Build gem

```bash
bundle exec bake gem:build
```

### Release

```bash
bin/release-gem        # compares local vs remote version, builds & pushes
bin/increment-version  # bumps major/minor/patch via ERB template
```

### Fetch upstream Matrix schemas

```bash
bin/fetch-matrix-schemas      # event type schemas -> data/
bin/fetch-matrix-api-schemas  # Client-Server OpenAPI specs -> data/
```

### Serve locally

```bash
falcon serve --bind http://0.0.0.0:9292
```

Requires a `config.ru` (see `examples/echo_bot/` for a working template).

## Architecture

### Entry point and module loading

`lib/async/matrix.rb` defines the `Async::Matrix` module and auto-requires **every `.rb` file** under `lib/async/matrix/` via `Dir.glob`. All source lives under the `Async::Matrix` namespace.

### Inline co-located tests (scampi)

Every source file ends with a `test do ... end` block containing its own unit tests. The test DSL uses `describe`/`it` blocks with `value.should == expected` assertions and `lambda { ... }.should.raise(ErrorClass)` for exceptions. Test infrastructure stubs (`FakeBody`, `FakeResponse`, `FakeInternet`) are defined in `lib/async/matrix/client.rb`'s test block.

### Application Service protocol (Rack 3 app)

`ApplicationService::Server` is a Rack 3 `#call(env)` app implementing four Matrix AS API routes:

- `PUT /_matrix/app/v1/transactions/{txnId}` — receive events (authenticated, idempotent)
- `GET /_matrix/app/v1/users/{userId}` — user existence (returns 200)
- `GET /_matrix/app/v1/rooms/{roomAlias}` — room alias (returns 404)
- `POST /_matrix/app/v1/ping` — healthcheck (no auth)

**Event flow:** Homeserver PUT -> Server authenticates (constant-time compare on hs_token) -> TransactionStore deduplicates (in-memory LRU, prunes oldest half at capacity 1024) -> Transaction wraps body -> Dispatcher iterates events -> matching Handlers called. Errors in one handler do not prevent others from running.

### Handler duck-type

Any object with `#event_types -> Array<String>` and `#call(event)` is a handler. Two creation paths:

1. **Plain handler class** — implement the two methods directly
2. **Bot DSL** — `Bot.new(client) { on "m.room.message", msgtype: "m.text", not_from: :self do |event| ... end }` generates `Handler` objects with filter support. The `Context` inner class provides helper methods (`send_text`, `send_notice`, `join_room`, etc.).

Register handlers via `server.register(handler_or_bot)`.

### Runtime-generated API from OpenAPI schemas

`client.api` returns a `Gateway` that starts method chains validated against the Matrix Client-Server OpenAPI specs stored in `data/matrix-spec/api/client-server/`.

- **PathTree** — trie loaded from OpenAPI YAML; template segments (`{roomId}`) become wildcards
- **Chain** — inherits `BasicObject` so that methods like `send`, `display`, `format` fall through to `method_missing`. Records path segments, then `.get()/.post()/.put()/.delete()` validates against PathTree and dispatches
- **Binary route detection** — upload/download/thumbnail paths dispatch to `MediaClient` instead of the JSON `Client`
- **Version rewriting** — media endpoints at `/v3` are rewritten to `/v1` where spec requires

### Schema-driven event validation

`Schema::Registry` (singleton) lazily loads Matrix event YAML schemas from `data/matrix-spec/event-schemas/schema/` using `json_schemer`. Supports base schemas and variant schemas (filename convention: `m.room.message$m.text` split on `$`). Custom format validators handle `mx-user-id`, `mx-room-id`, `mx-event-id`, etc. Events expose `valid?` (returns bool) and `valid!` (raises `ValidationError` with human-readable key paths).

### Configuration with JSON Schema validation

`ApplicationService::Config` loads YAML appservice config and validates against a 17-file JSON Schema suite under `lib/async/matrix/application_service/config/schema/` (mirrors mautrix bridgev2 Go structs). `json_schemer` with `insert_property_defaults: true` auto-fills defaults. The `Vivify` module provides dot-notation access with autovivification: `config.homeserver.address`.

### Client HTTP layer

`Client` wraps `Async::HTTP::Internet` (fiber-safe connection pooling) with:

- Bearer token auth (as_token from config)
- Exponential backoff with full jitter for 502/503/504
- Retry-After header parsing (delta-seconds and HTTP-date) for 429
- Per-request `max_retries:` override
- Response size limiting (50 MiB for JSON, 512 KiB for errors) with streaming enforcement
- `MediaClient` for binary upload/download operations

### Data directory

`data/` contains bundled Matrix specification schemas (fetched from matrix-org/matrix-spec via `bin/fetch-matrix-schemas` and `bin/fetch-matrix-api-schemas`). These are YAML files included in the gem package.

### Examples

`examples/` contains complete working applications with Docker Compose stacks:

- `echo_bot/` — minimal echo bot with Synapse + FluffyChat
- `brute/` — AI agent bot (passes `ANTHROPIC_API_KEY`)
- `lindsey_and_dave/` — two-bot example
- `synapse/` — shared Synapse + FluffyChat + Nginx reverse proxy base stack
