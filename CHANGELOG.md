# Changelog

All notable changes to **async-matrix** are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

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

### Breaking changes

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

### Changed

- Reworked the dispatcher and transaction store around the new
  `TransactionHandler`.
- Query parameters are now supported on all HTTP client methods.
- Updated all bundled examples (`echo_bot`, `brute`, `brute-steering`,
  `lindsey_and_dave`, `inbound_webhook_bot`) to the new server API; dropped the
  checked-in `Gemfile.lock` files in favour of a shared test harness
  (`examples/run_test.sh`).
- Improved event logging.

## [1.2.1] - 2026

- Fixed the Ruby 4.0 build by bumping the native `magnus` binding from 0.7 to
  0.8.

## [1.2.0] - 2026

- Added end-to-end encryption (Olm/Megolm) via a native `vodozemac` binding.

## [1.0.0] - 2026

- First release: async-native Matrix Application Service SDK built on the
  Socketry ecosystem, with schema-driven event validation, an OpenAPI-backed
  client, media support, and mautrix-compatible configuration.

[2.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.0
[1.2.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.1
[1.2.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.0
[1.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.0.0
