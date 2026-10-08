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

**async-matrix** is an async-native Matrix *protocol* library for Ruby (gem: `async-matrix`, version 2.1.0). Built entirely on the Socketry ecosystem (`async`, `async-http`, Falcon) using fibers. Licensed Apache 2.0, authored by Nathan Kidd at General Intelligence Systems.

Scope is the protocol layer: the Client-Server API client, schema-validated events, media, and end-to-end encryption. The Application Service *server* side — receiving homeserver transactions, dispatching events to handlers, the Bot DSL, the bridgev2 config schema suite — lives in the sibling gem **async-matrix-bridge** (`Async::Matrix::Bridge::ApplicationService::*`) at `../async-matrix-bridge`. Do not add app-service or bridge code here; it belongs there.

Requires Ruby >= 3.3. Uses Nix flake for dev environment (`.envrc` + `flake.nix`).

## Commands

### Run tests

```bash
bin/test
# or directly:
CONSOLE_LEVEL=fatal bundle exec scampi
```

Tests use **scampi** (inline co-located test framework). There is no `test/` or `spec/` directory — tests live in an `__END__` section **at the bottom of every source file** (Ruby stops parsing at `__END__`, so specs never load in production). Scampi discovers them via ripgrep (files with an `__END__` section whose tail begins with `describe`/`context`/`shared`/`it`).

Run the whole suite with `bin/test` (`CONSOLE_LEVEL=fatal bundle exec scampi`). Single-file runs (`scampi <file>`) are **not** supported: source files no longer eagerly `require` the rest of the library, so a lone file can't resolve the sibling constants its specs reference — the full run loads every file, which is what makes cross-file references (and shared stubs) resolve.

### Lint

```bash
bin/rubocop
```

`.rubocop.yml` runs with `DisabledByDefault` and enables a hand-picked set, plus eight local cops in `cops/`. `Local/ConstantMatchesPath` is the one to know: every file under `lib/` must define the constant its path spells, Zeitwerk-style, so `lib/async/matrix/config/vivify.rb` defines `Async::Matrix::Config::Vivify` and nothing else at top level.

### Build gem

```bash
bundle exec bake gem:build
```

### Release

```bash
gem kit bump [major|minor|patch]  # version.rb via the .erb, then relock
gem kit changelog --write         # draft this version's entry
bin/release-gem                   # build + push, source gem AND platform gems
```

`gem kit bump` supersedes the old `bin/increment-version` — same ERB render,
plus it blocks a bump onto a due deprecation deadline and relocks with
`BUNDLE_FROZEN=false` (bare `bundle install` inherits the devshell's frozen
store Gemfile and fails).

`bin/release-gem` is **not** superseded by `gem kit release`, which does one
`gem build` + one `gem push` and has no notion of per-platform gems. This gem
has a native extension, so publishing only the source gem would put a Rust
toolchain back in every user's install path — the regression 2.0.1 was cut to
fix. `bin/release-gem` builds the source gem locally and downloads the
precompiled platform gems from the latest green `cross-compile.yml` run, so
**push to main and let that workflow finish before releasing**.

The tradeoff: `bin/release-gem` skips the `gem kit release` gates (changelog
entry, deprecation deadlines, clean working tree). Run `gem kit release
--dry-run` first to get them.

### Fetch upstream Matrix schemas

```bash
bin/fetch-matrix-schemas      # event type schemas -> data/
bin/fetch-matrix-api-schemas  # Client-Server OpenAPI specs -> data/
```

## Architecture

### Entry point and module loading

`lib/async/matrix.rb` defines the `Async::Matrix` module and auto-requires **every `.rb` file** under `lib/async/matrix/` via `Dir.glob`. All source lives under the `Async::Matrix` namespace. Source files do **not** self-`require "async/matrix"`; they rely on the glob loader for ordering, plus targeted `require_relative` for the few load-time cross-file dependencies (e.g. `double_puppet_client.rb` → `client`, `config.rb` → `config/vivify`, `schema/validation_error.rb` → `error`).

### Inline co-located tests (scampi)

Every source file ends with an `__END__` section containing its own unit tests. The test DSL uses `describe`/`it` blocks with `value.should == expected` assertions and `lambda { ... }.should.raise(ErrorClass)` for exceptions. Scampi evaluates each `__END__` tail in `TOPLEVEL_BINDING`, so infrastructure stubs (`FakeBody`, `FakeResponse`, `FakeInternet`) defined in `lib/async/matrix/client.rb`'s `__END__` section are visible to every other file's specs.

Scampi `require`s only the files it discovers (those with an `__END__` tail), so nothing loads `lib/async/matrix.rb` or its glob. Constants still resolve because `bundler/setup` evaluates `async-matrix.gemspec`, which `require_relative`s `lib/async/matrix/version.rb` — which is why a broken `BUNDLE_GEMFILE` shows up as ~60 `uninitialized constant Async::Matrix::VERSION` errors rather than as a bundler failure. See the `extraConfigPaths` comment in `flake.nix`.

### Client HTTP layer

`Client` wraps `Async::HTTP::Internet` (fiber-safe connection pooling) with:

- Bearer token auth (`as_token` from config)
- Exponential backoff with full jitter for 502/503/504
- Retry-After header parsing (delta-seconds and HTTP-date) for 429
- Per-request `max_retries:` override
- Response size limiting (50 MiB for JSON, 512 KiB for errors) with streaming enforcement
- `MediaClient` for binary upload/download operations
- `DoublePuppetClient`, a subclass authenticating as a puppeted user rather than the appservice

`Client` duck-types on its config: it reads only `config.homeserver.address` and `config.appservice.as_token`, so anything answering those works.

### Runtime-generated API from OpenAPI schemas

`client.api` returns a `Gateway` that starts method chains validated against the Matrix Client-Server OpenAPI specs stored in `data/matrix-spec/api/client-server/`.

- **PathTree** — trie loaded from OpenAPI YAML; template segments (`{roomId}`) become wildcards
- **Chain** — inherits `BasicObject` so that methods like `send`, `display`, `format` fall through to `method_missing`. Records path segments, then `.get()/.post()/.put()/.delete()` validates against PathTree and dispatches
- **Binary route detection** — upload/download/thumbnail paths dispatch to `MediaClient` instead of the JSON `Client`
- **Version rewriting** — media endpoints at `/v3` are rewritten to `/v1` where spec requires

### Events and schema-driven validation

`Schema::Registry` (singleton) lazily loads Matrix event YAML schemas from `data/matrix-spec/event-schemas/schema/` using `json_schemer`. Supports base schemas and variant schemas (filename convention: `m.room.message$m.text` split on `$`). Custom format validators handle `mx-user-id`, `mx-room-id`, `mx-event-id`, etc.

`Schema.parse(hash)` returns an `Async::Matrix::Event`: typed envelope accessors plus an `Async::Matrix::Content` for the content object, which is dot-accessible via `method_missing` over the raw hash. Events expose `valid?` (returns bool) and `valid!` (raises `Schema::ValidationError` with human-readable key paths).

### Configuration

`Async::Matrix::Config` loads YAML (or takes a hash) and exposes it through `Config::Vivify`, a mixin giving a Hash dot-notation access with autovivification. Top-level sections are an explicit `def_delegators` list, not a `method_missing` forward, so a typo'd section raises `NoMethodError` instead of autovivifying.

It validates **nothing**. `.validate!` is a no-op class-method hook called with the raw hash before vivification; a subclass overrides it to raise (and may mutate the hash to insert defaults). That is the seam async-matrix-bridge uses to layer the mautrix bridgev2 JSON Schema suite on top.

### End-to-end encryption

`Async::Matrix::E2EE` wraps a native Rust extension (`ext/async_matrix_e2ee`, magnus over [vodozemac](https://github.com/matrix-org/vodozemac)) compiled into `lib/async/matrix/async_matrix_e2ee.so` by `rake compile`. **The suite cannot run without it** — `e2ee.rb`'s `require_relative` raises `LoadError` at load time and takes down the whole run, which is why CI builds the extension before `scampi`.

`.github/workflows/cross-compile.yml` cross-compiles per-platform precompiled gems via the oxidize-rb toolchain, so `gem install async-matrix` needs no Rust on those platforms. `bin/release-gem` builds the source gem locally, downloads the precompiled gems from the latest green CI run, and pushes all of them.

### Data directory

`data/` contains bundled Matrix specification schemas (fetched from matrix-org/matrix-spec via `bin/fetch-matrix-schemas` and `bin/fetch-matrix-api-schemas`). These are YAML files included in the gem package.
