# Changelog

All notable changes to **async-matrix** are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.0.0] - 2026-10-08

The Application Service layer has moved out of this gem into
[async-matrix-bridge](https://github.com/general-intelligence-systems/async-matrix-bridge).
async-matrix is now the Matrix *protocol* layer only: the Client-Server API
client, events and schema validation, media, and end-to-end encryption.

### Added

- **`Async::Matrix::Config`** — the config loading and `Vivify` dot-notation
  access that used to sit on `ApplicationService::Config`, minus the schema.
  It validates nothing; `.validate!` is a no-op class-method hook a subclass
  overrides to raise, which is the seam async-matrix-bridge uses to layer the
  bridgev2 JSON Schema suite back on. `Client` only ever read
  `homeserver.address` and `appservice.as_token`, so nothing in this gem needs
  the schema. `Config.load(path)` and `Config#bot_mxid` are unchanged; top-level
  sections remain an explicit `def_delegators` list, so a typo'd section still
  raises `NoMethodError` instead of autovivifying.

### Changed

- **`ApplicationService::Event` is now `Async::Matrix::Event`**, and
  `ApplicationService::Content` is `Async::Matrix::Content`. Neither was
  application-service-specific — `Schema.parse` returns one — and both are now
  in the namespace they describe, one constant per file.
- **`ApplicationService::ErrorResponse` is now `Async::Matrix::ErrorResponse`**,
  for the same reason: `Client` and `MediaClient` parse every failed response
  into one.
- Raised the minimum runtime dependencies to `async ~> 2.46`,
  `async-http ~> 0.105` and `json_schemer ~> 2.5`.
- The documentation site is now built with
  [just-the-docs](https://just-the-docs.com/) instead of utopia-project, at the
  same `documentation_uri`.

### Removed

- **`Async::Matrix::ApplicationService::*`** — `Server`, `Bot`, `Dispatcher`,
  `TransactionHandler`, `Transaction`, `TransactionStore`, and the bridgev2
  `Config` schema suite now live in async-matrix-bridge as
  `Async::Matrix::Bridge::ApplicationService::*`. Add that gem and
  `require "async/matrix/bridge"`; the class names are otherwise unchanged.
- **`Async::Matrix::Bridge::Discord` and `Async::Discord`** — the Discord
  bridge database layer and the Discord API/gateway client are gone, with no
  replacement. This drops the `sequel`, `async-websocket` and `sqlite3`
  dependencies.
- **`grape`** is no longer a dependency; it belongs to the application service,
  and so now to async-matrix-bridge. `falcon` is likewise no longer a
  development dependency.
- **`Config.schema` and `Config::SCHEMA_DIR`**, with the bundled bridgev2 JSON
  Schema files. `Config.validate!` is now a no-op, so `Config.new` no longer
  raises `BadJsonError` for a config that fails the schema, and no longer
  inserts the schema's property defaults into the data. Subclass `Config` and
  override `.validate!` — or use async-matrix-bridge's `Config` — if you want
  either back.
- `bin/fetch-discord-api-spec`, and `examples/` (which are all application
  services — they moved to async-matrix-bridge too).

### Fixed

- `lib/async/matrix.rb` no longer calls `require "bundler/setup"`. A library
  has no business activating the host application's bundle, and doing so broke
  any application whose own `Gemfile` did not already match.

### Security

- Dropping `grape` removes `activesupport` and with it `concurrent-ruby` from
  the dependency tree entirely, which closes GHSA-h8w8-99g7-qmvj (plus two low
  advisories) for this gem. The transitive pin had already been bumped to
  `concurrent-ruby 1.3.7` before the dependency was removed.

## [2.1.0] - 2026-08-01

Megolm room keys can now be imported from key backup and from forwarded
sessions, and exported for the same.

### Added

- `InboundGroupSession.import(exported_key)` — build a session from a base64
  **exported** session key. Server-side key backup
  (`m.megolm_backup.v1.curve25519-aes-sha2`) and `m.forwarded_room_key` both
  carry an `ExportedSessionKey`, which is version 1 and carries no signature,
  while `InboundGroupSession.new` requires a signed version-2 `SessionKey` and
  rejects them outright. Without `import`, a client can never read history it
  did not receive a live `m.room_key` for.
- `InboundGroupSession#export_at(index)` and
  `InboundGroupSession#export_at_first_known_index` — export a session in that
  same format, for uploading to key backup or forwarding to another device.
  `export_at` returns `nil` once the ratchet has advanced past `index`; megolm
  ratchets forward only, so earlier indices are unrecoverable by design.

Sessions built with `import` are not signature-verified, because an exported
key has no signature to verify. That is inherent to the format — the spec
likewise treats backup-restored keys as unverified.

## [2.0.1] - 2026-07-09

Packaging release: `gem install async-matrix` no longer requires a Rust
toolchain.

### Changed

- **Precompiled native gems.** The Rust/vodozemac E2EE extension is now
  cross-compiled into per-platform ("fat") gems via the rb-sys/oxidize-rb
  toolchain, so RubyGems serves users a prebuilt `.so` matching their platform
  instead of compiling from source at install time. Source compilation remains
  as a fallback for unsupported platforms.
- Switched the `Rakefile` from `Rake::ExtensionTask` to `RbSys::ExtensionTask`
  and added a workspace-root `Cargo.toml`/`Cargo.lock` (the lockfile moved out
  of `ext/`), which the cross-compilation toolchain resolves from.
- `e2ee.rb` now loads the compiled object from the per-Ruby-version subdirectory
  used by fat gems, falling back to the flat path for local source builds.
- Added a CI workflow that cross-compiles the platform gems on push to `main`
  and uploads them as build artifacts (publishing remains a manual step).

## [2.0.0] - 2026-07-09

Major release. The Application Service server has been rebuilt on
[Grape](https://github.com/ruby-grape/grape), and transaction handling has been
extracted into a dedicated, long-lived object. These are breaking changes to the
server-side API.

### Changed

- **Grape-based Application Service server.** `ApplicationService::Server` now
  wraps a `Grape::API` instead of a hand-rolled Rack app. It forwards the Grape
  route DSL, so application-specific endpoints can be declared alongside the
  Matrix wire-protocol routes. Adds a runtime dependency on `grape ~> 3.3`.
- **Event registration via `#dispatch`.** Handlers and bots are now attached
  with the `dispatch { on "m.room.message" do |event| … end }` DSL on the
  server, replacing the previous `#register` flow.
- **`TransactionHandler` introduced.** Idempotent transaction processing and
  handler routing now live in `ApplicationService::TransactionHandler`, a stable
  long-lived object, rather than in the stateless HTTP layer. The Bot/handler
  duck-type (`#event_types`, `#call`) is unchanged.
- **`scampi` is now a development dependency** (bumped to `~> 1.0`) instead of a
  runtime dependency. Inline co-located tests moved to `__END__` sections.
- Reworked the dispatcher and transaction store around the new
  `TransactionHandler`.
- Query parameters are now supported on all HTTP client methods.
- Updated all bundled examples (`echo_bot`, `brute`, `brute-steering`,
  `lindsey_and_dave`, `inbound_webhook_bot`) to the new server API; dropped the
  checked-in `Gemfile.lock` files in favour of a shared test harness
  (`examples/run_test.sh`).
- Improved event logging.

## [1.2.1] - 2026-06-08

### Fixed

- Fixed the Ruby 4.0 build by bumping the native `magnus` binding from 0.7 to
  0.8.

## [1.2.0] - 2026-06-08

### Added

- Added end-to-end encryption (Olm/Megolm) via a native `vodozemac` binding.

## [1.0.0] - 2026-04-28

### Added

- First release: async-native Matrix Application Service SDK built on the
  Socketry ecosystem, with schema-driven event validation, an OpenAPI-backed
  client, media support, and mautrix-compatible configuration.

[Unreleased]: https://github.com/general-intelligence-systems/async-matrix/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v3.0.0
[2.1.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.1.0
[2.0.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.1
[2.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.0
[1.2.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.1
[1.2.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.0
[1.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.0.0
